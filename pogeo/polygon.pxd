from libcpp.vector cimport vector

from .geo.s2polygon cimport S2Polygon
from .geo.s2polygonbuilder cimport S2PolygonBuilder


cdef class Polygon:
    cdef S2Polygon polygon
    cdef readonly double south, east, north, west
    cdef void create_loop(self, tuple points, S2PolygonBuilder* lv, int depth)
