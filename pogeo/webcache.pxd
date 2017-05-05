# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=str, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint32_t
from libcpp.set cimport set
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map

from .json cimport Json

cdef class WebCache:
    cdef:
        Json.array cache
        set[int16_t] trash
        unordered_map[int16_t, string] names
        tuple query
        object session_maker
        int last_id
        uint32_t last_update

    cdef void update_cache(self)
    cdef string get_first(self)
