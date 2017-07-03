from libc.stdint cimport uint32_t, uint64_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from cpython.array cimport array

from .geo.s2 cimport S2Point
from .location cimport Location
from .types cimport shape


cdef array ARRAY_TEMPLATE
cdef S2Point cellid_to_s2point(uint64_t cellid)
cdef S2Point token_to_s2point(string token)
cpdef double get_bearing(Location point1, Location point2)
cpdef double get_distance(Location p1, Location p2)
cpdef double get_distance_unit(Location p1, Location p2, char unit)
cdef float monotonic()
cdef float float_time()
cdef uint32_t int_time()
cdef vector[S2Point] get_s2points(shape bounds, int level)
cdef double s2point_to_lat(S2Point p)
cdef double s2point_to_lon(S2Point p)
cdef S2Point coords_to_s2point(double lat, double lon)
