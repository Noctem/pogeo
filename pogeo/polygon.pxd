from libcpp.vector cimport vector

from cpython cimport bool as pybool

from .geo.s2loop cimport S2Loop


cdef class Polygon:
    cdef S2Loop loop
    cdef readonly double south, east, north, west
    cdef readonly pybool multi
    cdef readonly vector[double] center
