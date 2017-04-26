from cpython cimport bool as pybool

from .geo.s2loop cimport S2Loop


cdef class Polygon:
    cdef S2Loop loop
    cdef readonly double south, east, north, west
