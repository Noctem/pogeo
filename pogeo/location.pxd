from libc.stdint cimport uint32_t

from .geo.s2 cimport S2Point


cdef class Location:
    cdef double latitude, longitude
    cdef public double altitude
    cdef readonly uint32_t time
    cdef S2Point point
    @staticmethod
    cdef from_point(S2Point point)
    cdef double lat_radian(self)
    cdef double lon_radian(self)
