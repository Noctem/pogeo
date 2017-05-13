from libcpp cimport bool
from libc.stdint cimport uint32_t

from ._mutex cimport mutex
from ._shared_mutex cimport shared_timed_mutex
from .._json cimport Json

cdef class SpawnCache:
    cdef:
        Json.array cache
        bool int_id
        object Spawnpoint
        object session_maker
        int last_id
        uint32_t next_update
        mutex db_lock
        shared_timed_mutex vector_lock

    cdef void update_cache(self)
    cdef void process_results(self, object cursor)
