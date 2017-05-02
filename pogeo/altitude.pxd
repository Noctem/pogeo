from libc.stdint cimport uint8_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map

from .cpython_ cimport Py_uhash_t


cdef class AltitudeCache:
    cdef readonly unordered_map[uint64_t, float] cache
    cdef bool changed
    cdef uint8_t level
    cdef double rand_min, rand_max
    cdef Py_uhash_t bounds_hash
