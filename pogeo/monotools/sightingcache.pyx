# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from cpython cimport bool as pybool

from ._gzip cimport compress
from ._vectorutils cimport dump_after_id, remove_expired
from .._json cimport Json
from .._mcpp cimport emplace, emplace_move, push_back_move
from ..geo.s2 cimport S2Point
from ..utils cimport cellid_to_s2point, int_time, s2point_to_lat, s2point_to_lon, token_to_s2point

from sqlalchemy.orm import loading

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

        self.names = {k: v.encode('utf-8') for k, v in names.POKEMON.items()}

        s = db.Sighting
        if self.extra:
            self.columns = (
                s.id, s.pokemon_id, s.spawn_id, s.expire_timestamp, s.move_1,
                s.move_2, s.atk_iv, s.def_iv, s.sta_iv)
            self.moves = {k: v.encode('utf-8') for k, v in names.MOVES.items()}
            self.damage = dict(names.DAMAGE)
        else:
            self.columns = s.id, s.pokemon_id, s.spawn_id, s.expire_timestamp

        self.session_maker = db.Session
        self.next_clean = int_time() + 60

    cdef void update_cache(self):
        if not self.db_lock.try_lock():
            # wait for the other DB thread but then return since we don't need
            # to update the cache again already
            self.db_lock.lock()
            self.db_lock.unlock()
            return

        session = self.session_maker(autoflush=False)
        try:
            query = session.query(*self.columns).filter(self.columns[EXPIRATION] > int_time() + 10, self.columns[INDEX] > self.last_id)
            if self.filter_ids is not None:
                query = query.filter(~self.query[POKEMON_ID].in_(self.filter_ids))
            query = query.order_by(self.columns[EXPIRATION].desc())

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
            int id_
            int16_t pokemon_id, move1, move2
            S2Point point

        self.vector_lock.lock()
        while True:
            pokemon = <tuple>cursor.fetchone()
            if pokemon is None:
                self.vector_lock.unlock()
                return

            id_ = pokemon[INDEX]
            if id_ > self.last_id:
                self.last_id = id_

            emplace_move(jobject, b'id', id_)
            emplace_move(jobject, b'pid', <int>pokemon[POKEMON_ID])
            point = (cellid_to_s2point(<uint64_t>pokemon[SPAWN_ID])
                     if self.int_id else
                     token_to_s2point(string(<char*>pokemon[SPAWN_ID])))
            emplace_move(jobject, b'lat', s2point_to_lat(point))
            emplace_move(jobject, b'lon', s2point_to_lon(point))

            pokemon_id = pokemon[POKEMON_ID]
            emplace_move(jobject, b'trash', self.trash.find(pokemon_id) != self.trash.end())
            emplace(jobject, b'name', self.names[pokemon_id])
            emplace_move(jobject, b'expire', <int>pokemon[EXPIRATION])

            if self.extra and pokemon[MOVE1] is not None:
                move1 = pokemon[MOVE1]
                move2 = pokemon[MOVE2]
                emplace_move(jobject, b'atk', <int>pokemon[ATKIV])
                emplace_move(jobject, b'def', <int>pokemon[DEFIV])
                emplace_move(jobject, b'sta', <int>pokemon[STAIV])
                emplace(jobject, b'move1', self.moves[move1])
                emplace(jobject, b'move2', self.moves[move2])
                emplace(jobject, b'damage1', self.damage[move1])
                emplace(jobject, b'damage2', self.damage[move2])
            push_back_move(self.cache, jobject)

    def get_json(self, int last_id, bool gz=True):
        if int_time() > self.next_update:
            self.update_cache()

        cdef uint32_t now = int_time()
        if now > self.next_clean:
            self.vector_lock.lock()
            remove_expired(self.cache, now)
            self.vector_lock.unlock()
            self.next_clean = now + 35

        cdef string jsonified

        self.vector_lock.lock_shared()
        if last_id == 0:
            if gz:
                compress(Json(self.cache).dump(), jsonified, COMPRESSION)
            else:
                return Json(self.cache).dump(jsonified)
        elif gz:
            compress(dump_after_id(self.cache, last_id), jsonified, COMPRESSION)
        else:
            dump_after_id(self.cache, last_id, jsonified)
        self.vector_lock.unlock_shared()

        return jsonified
