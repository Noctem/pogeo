# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8

from libc.stdint cimport uint8_t, uint64_t
from libcpp cimport bool
from libcpp.unordered_map cimport unordered_map

from ._cpython cimport Py_hash_t
from .location cimport Location


cdef class AltitudeCache:
    cdef:
        unordered_map[uint64_t, float] cache
        bool changed
        uint8_t level
        unicode key
        double rand_min, rand_max
        Py_hash_t bounds_hash
    cpdef double get(self, Location loc)
