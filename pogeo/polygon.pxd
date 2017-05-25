from ._json cimport Json
from .geo.s2polygon cimport S2Polygon
from .geo.s2polygonbuilder cimport S2PolygonBuilder


cdef class Polygon:
    cdef S2Polygon shape
    cdef readonly double south, east, north, west
    cdef void _initialize(self)
    @staticmethod
    cdef void unpickle_loop(list points, S2PolygonBuilder &builder, int depth)
    @staticmethod
    cdef void create_loop(tuple points, S2PolygonBuilder &builder, int depth)
    @staticmethod
    cdef void create_loop_from_geojson(Json.array &points, S2PolygonBuilder &builder, int depth)
    @staticmethod
    cdef Polygon from_geojson(Json.array polygons)
