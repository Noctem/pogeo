# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t
from libcpp cimport bool
from libcpp.set cimport set
from libcpp.string cimport string
from libcpp.map cimport map

from ._mutex cimport mutex
from ._shared_mutex cimport shared_timed_mutex
from .._json cimport Json


cdef class SightingCache:
    cdef:
        Json.array cache
        set[int16_t] trash
        map[int16_t, string] names
        map[int16_t, string] moves
        map[int16_t, int16_t] damage
        tuple filter_ids
        bool extra
        tuple columns
        object session_maker
        bool int_id
        int last_id
        uint32_t next_update
        uint32_t next_clean
        mutex db_lock
        shared_timed_mutex vector_lock

    cdef void update_cache(self)
    cdef void process_results(self, object cursor)
