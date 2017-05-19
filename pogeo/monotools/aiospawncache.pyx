# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8, cdivision=True

from libc.stdint cimport uint8_t, uint32_t, uint64_t
from libc.stdio cimport snprintf
from libcpp cimport bool
from libcpp.string cimport string

from ._gzip cimport compress
from .aiolock cimport AioLock
from .._bitscan cimport leadingZeros
from .._json cimport Json
from .._mcpp cimport emplace, emplace_move, push_back_move
from ..geo.s2 cimport S2Point
from ..geo.s2cellid cimport S2CellId
from ..utils cimport int_time, s2point_to_lat, s2point_to_lon, token_to_s2point

DEF INDEX = 0
DEF DURATION = 1
DEF SPAWN_ID = 2
DEF DESPAWN = 3

DEF COMPRESSION = 9


cdef class AioSpawnCache:
    def __cinit__(self, bool int_id):
        self.int_id = int_id

    def initialize(self, loop, pool):
        self.pool_acquire = pool.acquire
        self.lock = AioLock(loop=loop)
        loop.create_task(self.update_cache())

    async def update_cache(self):
        if self.lock.locked:
            return await self.lock.wait()

        cdef list results

        async with self.lock:
            async with self.pool_acquire() as conn:
                results = await conn.fetch(f'SELECT id, duration, spawn_id, despawn_time FROM spawnpoints WHERE id > {self.last_id}')

            self.process_results(results)
        self.next_update = int_time() + 120

    cdef void process_results(self, list results):
        cdef:
            Json.object_ jobject
            string token
            int id_, despawn_time
            S2Point point
            S2CellId cell
            uint64_t cellid
            char[7] buff
            Py_ssize_t i, length = len(results)

        for i in range(length):
            spawnpoint = results[i]

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
                    snprintf(buff, 7, "%um%us", <uint32_t>(despawn_time / 60), despawn_time % 60)
                else:
                    snprintf(buff, 7, "?")

                emplace_move(jobject, b'despawn_time', string(buff))

            emplace_move(jobject, b'duration', <int>(spawnpoint[DURATION] or 30))

            emplace_move(jobject, b'lat', s2point_to_lat(point))
            emplace_move(jobject, b'lon', s2point_to_lon(point))

            push_back_move(self.cache, jobject)

    async def get_json(self, bool gz=True):
        if int_time() > self.next_update:
            await self.update_cache()

        cdef string jsonified

        if gz:
            compress(Json(self.cache).dump(), jsonified, COMPRESSION)
        else:
            Json(self.cache).dump(jsonified)

        return jsonified
