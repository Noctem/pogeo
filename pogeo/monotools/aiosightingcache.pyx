# distutils: language = c++
# cython: language_level=3, c_string_type=bytes, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from cpython cimport bool as pybool

from ._gzip cimport compress
from ._vectorutils cimport dump_after_id, remove_expired
from .aiolock cimport AioLock
from .._json cimport Json
from .._mcpp cimport emplace, emplace_move, push_back_move
from ..geo.s2 cimport S2Point
from ..utils cimport cellid_to_s2point, int_time, s2point_to_lat, s2point_to_lon, token_to_s2point


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


cdef class AioSightingCache:
    def __cinit__(self, conf, names):
        self.trash = conf.TRASH_IDS
        self.int_id = conf.SPAWN_ID_INT
        self.extra = pybool(conf.ENCOUNTER)

        self.names = {k: v.encode('utf-8') for k,v in names.POKEMON.items()}

        if self.extra:
            self.columns = (
                'id, pokemon_id, spawn_id, expire_timestamp, move_1'
                'move_2, atk_iv, def_iv, sta_iv')
            self.moves = {k: v.encode('utf-8') for k,v in names.MOVES.items()}
            self.damage = dict(names.DAMAGE)
        else:
            self.columns = 'id, pokemon_id, spawn_id, expire_timestamp'

        self.next_clean = int_time() + 60

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
                results = await conn.fetch(f'SELECT {self.columns} FROM sightings WHERE expire_timestamp > {int_time() + 10} AND id > {self.last_id} ORDER BY expire_timestamp DESC')

            self.process_results(results)
        self.next_update = int_time() + 10

    cdef void process_results(self, list results):
        cdef:
            Json.object_ jobject
            int id_
            int16_t pokemon_id, move1, move2
            S2Point point
            Py_ssize_t i, length = len(results)

        for i in range(length):
            pokemon = results[i]

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

    async def get_json(self, int last_id, bool gz=True):
        if int_time() > self.next_update:
            await self.update_cache()

        cdef uint32_t now = int_time()
        if now > self.next_clean:
            remove_expired(self.cache, now)
            self.next_clean = now + 35

        cdef string jsonified

        if last_id == 0:
            if gz:
                compress(Json(self.cache).dump(), jsonified, COMPRESSION)
            else:
                return Json(self.cache).dump(jsonified)
        elif gz:
            compress(dump_after_id(self.cache, last_id), jsonified, COMPRESSION)
        else:
            dump_after_id(self.cache, last_id, jsonified)

        return jsonified
