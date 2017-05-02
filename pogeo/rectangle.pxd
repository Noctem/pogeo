from .geo.s2latlngrect cimport S2LatLngRect


cdef class Rectangle:
    cdef S2LatLngRect shape
    cdef readonly double south, east, north, west
    cdef bint unbound
