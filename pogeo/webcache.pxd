# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t
from libcpp cimport bool
from libcpp.set cimport set
from libcpp.string cimport string
from libcpp.map cimport map

from ._json cimport Json


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
        uint32_t last_update

    cdef void update_cache(self)
    cdef void get_first(self)
    cdef void process_results(self, object cursor)
    cdef void process_extra(self, tuple pokemon, Json.object_ &jobject)


cdef class SpawnCache:
    cdef:
        Json.array cache
        bool int_id
        object Spawnpoint
        object session_maker
        int last_id
        uint32_t last_update

    cdef void update_cache(self)
    cdef void process_results(self, object cursor)
