from ._json cimport Json
from .geo.s2polyline cimport S2Polyline

cdef class Polyline:
    cdef S2Polyline line

    @staticmethod
    cdef Polyline from_geojson(Json.array coords)
