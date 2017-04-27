# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport pow
from libcpp cimport bool
from libcpp.vector cimport vector

from .const cimport EARTH_RADIUS_KILOMETERS
from .cpylib cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s2 cimport S2, S2Point
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
from .location cimport Location
from .utils cimport coords_to_s2point, get_distance


cdef class Loop:
    def __cinit__(self, tuple points):
        cdef:
            double lat, lon
            vector[S2Point] v
            S2Point a, b, c
            tuple coords

        for coords in points:
            lat, lon = coords
            v.push_back(coords_to_s2point(lat, lon))

        self.loop.Init(v)
        a = v[0]
        b = v[1]
        c = v[2]
        cdef bool ccw = S2.SimpleCCW(a, b, c)
        if not ccw:
            self.loop.Invert()

        cdef S2LatLngRect rect = self.loop.GetRectBound()
        self.south = rect.lat_lo().degrees()
        self.east = rect.lng_hi().degrees()
        self.north = rect.lat_hi().degrees()
        self.west = rect.lng_lo().degrees()

    def __contains__(self, Location loc):
        cdef S2Point p = loc.point
        return self.loop.Contains(p)

    def __hash__(self):
        cdef Py_uhash_t mult = 1000003
        cdef Py_uhash_t x = 0x345678
        cdef Py_hash_t y

        cdef double[5] inputs = [self.south, self.east, self.north, self.west, <double>self.loop.num_vertices()]
        cdef double i
        for i in inputs:
            y = _Py_HashDouble(i)
            x = (x ^ y) * mult
            mult += <Py_hash_t>(82520 + 10)
        return x + 97531

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.loop.GetArea() * pow(EARTH_RADIUS_KILOMETERS, 2)
