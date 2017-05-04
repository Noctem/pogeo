from libc.stdint cimport uint32_t
from libcpp.vector cimport vector

from .array cimport array
from .geo.s2 cimport S2Point
from .location cimport Location
from .types cimport shape

cdef array ARRAY_TEMPLATE
cpdef double get_bearing(Location point1, Location point2)
cpdef double get_distance(Location p1, Location p2)
cpdef double get_distance_unit(Location p1, Location p2, char unit)
cdef float time()
cdef uint32_t int_time()
cdef vector[S2Point] get_s2points(shape bounds, int level)
cdef double s2point_to_lat(S2Point p)
cdef double s2point_to_lon(S2Point p)
cdef S2Point coords_to_s2point(double lat, double lon)
