# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from cpython cimport bool as pybool
from cpython.pythread cimport PyThread_acquire_lock, PyThread_allocate_lock, PyThread_free_lock, PyThread_release_lock

from cython.operator cimport preincrement as incr, dereference as deref

from ._gzip cimport compress
from ._vectorutils cimport dump_after_id, remove_expired
from .._json cimport Json
from ..geo.s2 cimport S2Point
from ..utils cimport cellid_to_s2point, int_time, s2point_to_lat, s2point_to_lon, token_to_s2point

from sqlalchemy.orm import loading
from threading import Lock

DEF INDEX = 0
DEF POKEMON_ID = 1
DEF SPAWN_ID = 2
DEF EXPIRATION = 3
DEF MOVE1 = 4
DEF MOVE2 = 5
DEF ATKIV = 6
DEF DEFIV = 7
DEF STAIV = 8

DEF COMPRESSION = 9


cdef class SightingCache:
    def __cinit__(self, conf, db, names):
        self.trash = conf.TRASH_IDS
        self.filter_ids = conf.MAP_FILTER_IDS
        self.int_id = conf.SPAWN_ID_INT
        self.extra = pybool(conf.ENCOUNTER)

        self.names = {k: v.encode('utf-8') for k,v in names.POKEMON.items()}

        s = db.Sighting
        if self.extra:
            self.columns = (
                s.id, s.pokemon_id, s.spawn_id, s.expire_timestamp, s.move_1,
                s.move_2, s.atk_iv, s.def_iv, s.sta_iv)
            self.moves = {k: v.encode('utf-8') for k,v in names.MOVES.items()}
            self.damage = dict(names.DAMAGE)
        else:
            self.columns = s.id, s.pokemon_id, s.spawn_id, s.expire_timestamp

        self.session_maker = db.Session

    cdef void update_cache(self):
        if not self.db_lock.try_lock():
            self.lock.lock()
            self.lock.unlock()
            return

        session = self.session_maker(autoflush=False)
        try:
            query = session.query(*self.columns).filter(self.columns[EXPIRATION] > int_time(), self.columns[INDEX] > self.last_id)
            if self.filter_ids is not None:
                query = query.filter(~self.query[POKEMON_ID].in_(self.filter_ids))

            context = query._compile_context()
            conn = query._get_bind_args(
                context,
                query._connection_from_session,
                close_with_result=True)

            cursor = conn.execute(context.statement, query._params)
            context.runid = loading._new_runid()

            self.process_results(cursor.cursor)
        except Exception as e:
            session.rollback()
            print(e)
            return
        finally:
            self.db_lock.unlock()
            cursor.close()
            session.close()
        self.next_update = int_time() + 10

    cdef void process_results(self, object cursor):
        cdef:
            tuple pokemon
            Json.object_ jobject
            string i_id = string(b'id')
            string i_pokemonid = string(b'pid')
            string i_lat = string(b'lat')
            string i_lon = string(b'lon')
            string i_trash = string(b'trash')
            string i_name = string(b'name')
            string i_expire = string(b'expire')
            int id_
            int16_t pokemon_id
            S2Point point
            Json null_json = Json()

        self.vector_lock.lock()
        while True:
            pokemon = <tuple>cursor.fetchone()
            if pokemon is None:
                return

            id_ = pokemon[INDEX]
            if id_ > self.last_id:
                self.last_id = id_

            jobject[i_id] = Json(id_)
            jobject[i_pokemonid] = Json(<int>pokemon[POKEMON_ID])

            point = (cellid_to_s2point(<uint64_t>pokemon[SPAWN_ID])
                     if self.int_id else
                     token_to_s2point(string(<char*>pokemon[SPAWN_ID])))
            jobject[i_lat] = Json(s2point_to_lat(point))
            jobject[i_lon] = Json(s2point_to_lon(point))

            pokemon_id = pokemon[POKEMON_ID]
            jobject[i_trash] = Json(self.trash.find(pokemon_id) != self.trash.end())
            jobject[i_name] = Json(self.names[pokemon_id])
            jobject[i_expire] = Json(<int>pokemon[EXPIRATION])

            if self.extra:
                if pokemon[MOVE1] is not None:
                    move1 = pokemon[MOVE1]
                    move2 = pokemon[MOVE2]
                    jobject[string(b'atk')] = Json(<int>pokemon[ATKIV])
                    jobject[string(b'def')] = Json(<int>pokemon[DEFIV])
                    jobject[string(b'sta')] = Json(<int>pokemon[STAIV])
                    jobject[string(b'move1')] = Json(self.moves[move1])
                    jobject[string(b'move2')] = Json(self.moves[move2])
                    jobject[string(b'damage1')] = Json(self.damage[move1])
                    jobject[string(b'damage2')] = Json(self.damage[move2])
                elif not jobject[string(b'move1')].is_null():
                    jobject[string(b'atk')] = null_json
                    jobject[string(b'def')] = null_json
                    jobject[string(b'sta')] = null_json
                    jobject[string(b'move1')] = null_json
                    jobject[string(b'move2')] = null_json
                    jobject[string(b'damage1')] = null_json
                    jobject[string(b'damage2')] = null_json

            self.cache.push_back(Json(jobject))
        self.vector_lock.unlock()

    def get_json(self, int last_id, bool gz=True):
        if int_time() > self.next_update:
            self.update_cache()

        cdef uint32_t now = int_time()
        if now > self.next_clean:
            self.vector_lock.lock()
            remove_expired(self.cache, now)
            self.vector_lock.unlock()
            self.next_clean = now + 35

        cdef string compressed

        self.vector_lock.lock_shared()
        try:
            if last_id == 0:
                if gz:
                    compress(Json(self.cache).dump(), compressed, COMPRESSION)
                    return compressed
                else:
                    return Json(self.cache).dump()
            elif gz:
                compress(dump_after_id(self.cache, last_id), compressed, COMPRESSION)
                return compressed
            else:
                return dump_after_id(self.cache, last_id)
        finally:
            self.vector_lock.unlock_shared()
