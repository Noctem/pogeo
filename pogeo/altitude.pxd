# cython: language_level=3

from libc.stdint cimport uint8_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map

from .cpython_ cimport Py_hash_t
from .location cimport Location


cdef class AltitudeCache:
    cdef:
        unordered_map[uint64_t, float] cache
        bool changed
        uint8_t level
        str key
        double rand_min, rand_max
        Py_hash_t bounds_hash
    cpdef double get(self, Location loc)
