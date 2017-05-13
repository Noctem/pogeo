# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8, cdivision=True

from libc.stdint cimport uint8_t, uint64_t
from libc.stdio cimport snprintf
from libcpp cimport bool
from libcpp.string cimport string

from ._gzip cimport compress
from .._bitscan cimport leadingZeros
from .._json cimport Json
from .._mcpp cimport emplace, emplace_move, push_back_move
from ..geo.s2 cimport S2Point
from ..geo.s2cellid cimport S2CellId
from ..utils cimport int_time, s2point_to_lat, s2point_to_lon, token_to_s2point

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
        if not self.db_lock.try_lock():
            # wait for the other DB thread but then return since we don't need
            # to update the cache again already
            self.db_lock.lock()
            self.db_lock.unlock()
            return

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
            self.db_lock.unlock()
            cursor.close()
            session.close()

        self.next_update = int_time() + 90

    cdef void process_results(self, object cursor):
        cdef:
            tuple spawnpoint
            Json.object_ jobject
            string token
            int id_, despawn_time
            S2Point point
            S2CellId cell
            uint64_t cellid
            char[7] buff

        self.vector_lock.lock()
        while True:
            spawnpoint = <tuple>cursor.fetchone()
            if spawnpoint is None:
                self.vector_lock.unlock()
                return

            id_ = spawnpoint[INDEX]
            if id_ > self.last_id:
                self.last_id = id_

            emplace_move(jobject, b'id', id_)

            if self.int_id:
                cellid = spawnpoint[SPAWN_ID]
                cell = S2CellId(cellid << leadingZeros(cellid))
                point = cell.ToPointRaw()
                token = cell.ToToken()
            else:
                token = string(<char*>spawnpoint[SPAWN_ID])
                point = token_to_s2point(token)

            emplace_move(jobject, b'spawn_id', token)
            if spawnpoint[DESPAWN] is None:
                emplace_move(jobject, b'despawn_time', b'?')
            else:
                despawn_time = spawnpoint[DESPAWN]
                if despawn_time > 0 and despawn_time < 60:
                    snprintf(buff, 7, "%us", despawn_time)
                elif despawn_time < 3600:
                    snprintf(buff, 7, "%um%us", despawn_time / 60, despawn_time % 60)
                else:
                    snprintf(buff, 7, "?")

                emplace_move(jobject, b'despawn_time', buff)

            emplace_move(jobject, b'duration', <int>(spawnpoint[DURATION] or 30))

            emplace_move(jobject, b'lat', s2point_to_lat(point))
            emplace_move(jobject, b'lon', s2point_to_lon(point))

            push_back_move(self.cache, jobject)

    def get_json(self, bool gz=True):
        if int_time() > self.next_update:
            self.update_cache()

        cdef string jsonified

        self.vector_lock.lock_shared()
        if gz:
            compress(Json(self.cache).dump(), jsonified, COMPRESSION)
        else:
            Json(self.cache).dump(jsonified)
        self.vector_lock.unlock_shared()

        return jsonified
