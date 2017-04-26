from libc.stdint cimport uint8_t, uint64_t

from .location cimport Location
from .geo.s2 cimport S2Point

cpdef double get_bearing(Location point1, Location point2)
cpdef double get_distance(Location p1, Location p2, char unit=?)
cdef uint8_t closest_level(double value)
cpdef double double_round(double x, int ndigits)
cdef S2Point coords_to_s2point(double lat, double lon)
