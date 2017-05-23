from ._json cimport Json
from .geo.s2loop cimport S2Loop


cdef class Loop:
    cdef S2Loop shape
    cdef readonly double south, east, north, west

    cdef void _initialize(self)
    @staticmethod
    cdef Loop from_geojson(Json.array coords)
