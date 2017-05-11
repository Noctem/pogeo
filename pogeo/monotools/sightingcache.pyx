# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from cpython cimport bool as pybool

from cython.operator cimport preincrement as incr, dereference as deref

from ._gzip cimport compress
from .._json cimport Json
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
        self.last_update = int_time()
        session = self.session_maker(autoflush=False)
        try:
            query = session.query(*self.columns).filter(self.columns[EXPIRATION] > self.last_update, self.columns[INDEX] > self.last_id)
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
        except Exception:
            session.rollback()
            raise
        finally:
            cursor.close()
            session.close()

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

        while True:
            pokemon = <tuple>cursor.fetchone()
            if pokemon is None:
                return

            jobject = Json.object_()

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

            if self.extra and pokemon[MOVE1] is not None:
                self.process_extra(pokemon, jobject)

            self.cache.push_back(Json(jobject))

    cdef void process_extra(self, tuple pokemon, Json.object_ &jobject):
        cdef int16_t move1, move2

        move1 = pokemon[MOVE1]
        move2 = pokemon[MOVE2]

        jobject[string(b'atk')] = Json(<int>pokemon[ATKIV])
        jobject[string(b'def')] = Json(<int>pokemon[DEFIV])
        jobject[string(b'sta')] = Json(<int>pokemon[STAIV])
        jobject[string(b'move1')] = Json(self.moves[move1])
        jobject[string(b'move2')] = Json(self.moves[move2])
        jobject[string(b'damage1')] = Json(self.damage[move1])
        jobject[string(b'damage2')] = Json(self.damage[move2])

    cdef void get_first(self):
        cdef string time_index = string(b'expire')
        it = self.cache.begin()
        while it != self.cache.end():
            if deref(it)[time_index].int_value() < int_time():
                self.cache.erase(it)
            else:
                incr(it)

    def get_json(self, int last_id, bool gz=True):
        if self.last_update + 5 < int_time():
            self.update_cache()

        cdef string compressed
        if last_id == 0:
            self.get_first()
            if gz:
                compress(Json(self.cache).dump(), compressed, COMPRESSION)
                return compressed
            else:
                return Json(self.cache).dump()

        cdef:
            Json.array jarray
            Json obj
            string id_index = string(b'id')
            string time_index = string(b'expire')

        it = self.cache.begin()
        while it != self.cache.end():
            obj = deref(it)

            if obj[time_index].int_value() < int_time():
                self.cache.erase(it)
            elif obj[id_index].int_value() < last_id:
                incr(it)
            else:
                jarray.push_back(obj)
                incr(it)

        if gz:
            compress(Json(jarray).dump(), compressed, COMPRESSION)
            return compressed
        else:
            return Json(jarray).dump()