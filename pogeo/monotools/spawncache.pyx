# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8

from libc.stdint cimport uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from ._gzip cimport compress
from .._json cimport Json
from ..geo.s2 cimport S2Point
from ..utils cimport cellid_to_s2point, int_time, s2point_to_lat, s2point_to_lon, token_to_s2point

from sqlalchemy.orm import loading

DEF INDEX = 0
DEF DURATION = 1
DEF SPAWN_ID = 2
DEF DESPAWN = 3

DEF COMPRESSION = 9


cdef class SpawnCache:
    def __cinit__(self, bool int_id, db):
        self.int_id = int_id
        self.Spawnpoint = db.Spawnpoint
        self.session_maker = db.Session

    cdef void update_cache(self):
        self.last_update = int_time()
        session = self.session_maker(autoflush=False)
        try:
            query = session.query(self.Spawnpoint.id, self.Spawnpoint.duration, self.Spawnpoint.spawn_id, self.Spawnpoint.despawn_time)

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
            tuple spawnpoint
            Json.object_ jobject
            string i_id = string(b'id')
            string i_lat = string(b'lat')
            string i_lon = string(b'lon')
            string i_spawnid = string(b'spawn_id')
            string i_despawn = string(b'despawn_time')
            string i_duration = string(b'duration')
            uint64_t cellid
            string token
            int id_
            S2Point point

        while True:
            spawnpoint = <tuple>cursor.fetchone()
            if spawnpoint is None:
                return

            id_ = spawnpoint[INDEX]
            if id_ > self.last_id:
                self.last_id = id_

            jobject[i_id] = Json(id_)

            if self.int_id:
                cellid = spawnpoint[SPAWN_ID]
                point = cellid_to_s2point(cellid)
                jobject[i_spawnid] = Json(<int>cellid)
            else:
                token = string(<char*>spawnpoint[SPAWN_ID])
                point = token_to_s2point(token)
                jobject[i_spawnid] = Json(token)

            jobject[i_despawn] = Json(<int>spawnpoint[DESPAWN])
            jobject[i_duration] = Json(<int>spawnpoint[DURATION])

            jobject[i_lat] = Json(s2point_to_lat(point))
            jobject[i_lon] = Json(s2point_to_lon(point))

            self.cache.push_back(Json(jobject))

    def get_json(self, bool gz=True):
        if self.last_update + 30 < int_time():
            self.update_cache()

        cdef string compressed

        if gz:
            compress(Json(self.cache).dump(), compressed, COMPRESSION)
            return compressed
        else:
            return Json(self.cache).dump()
