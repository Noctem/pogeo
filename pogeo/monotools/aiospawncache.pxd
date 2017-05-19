from libcpp cimport bool
from libc.stdint cimport uint32_t

from .aiolock cimport AioLock
from .._json cimport Json

cdef class AioSpawnCache:
    cdef:
        Json.array cache
        bool int_id
        object pool_acquire
        int last_id
        uint32_t next_update
        AioLock lock

    cdef void process_results(self, list results)
