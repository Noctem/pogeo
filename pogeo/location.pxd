from libc.stdint cimport uint32_t

from .geo.s2 cimport S2Point


cdef class Location:
    cdef double latitude, longitude
    cdef double altitude
    cdef readonly uint32_t time
    cdef S2Point point
    @staticmethod
    cdef Location from_point(S2Point point)
