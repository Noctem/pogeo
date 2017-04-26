# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t, int32_t
from libcpp cimport bool
from libcpp.vector cimport vector

from .cpylib cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s2 cimport S2, S2Point
from .geo.s2latlng cimport S2LatLng
from .location cimport Location
from .utils cimport coords_to_s2point, double_round, get_distance


cdef class Polygon:
    def __cinit__(self, tuple points):
        cdef double lat, lon
        cdef vector[S2Point] v
        cdef S2Point a, b, c
        cdef uint16_t length, i

        length = len(points)

        if length < 3:
            raise ValueError('Must provide at least 3 points.')

        lat, lon = points[0]
        self.south = self.north = lat
        self.east = self.west = lon
        v.push_back(coords_to_s2point(lat, lon))

        for i in range(1, length):
            lat, lon = points[i]
            if lat > self.north:
                self.north = lat
            elif lat < self.south:
                self.south = lat
            if lon > self.east:
                self.east = lon
            elif lon < self.west:
                self.west = lon
            v.push_back(coords_to_s2point(lat, lon))

        self.loop.Init(v)
        a = v[0]
        b = v[1]
        c = v[2]
        cdef bool ccw = S2.SimpleCCW(a, b, c)
        if not ccw:
            self.loop.Invert()

        cdef S2LatLng ll = S2LatLng(self.loop.GetCentroid())

    def __contains__(self, Location loc):
        cdef S2Point p = loc.point
        return self.loop.Contains(p)

    def __hash__(self):
        cdef Py_uhash_t mult = 1000003
        cdef Py_uhash_t x = 0x345678
        cdef Py_hash_t y
        cdef double[4] bounds = [self.south, self.east, self.north, self.west]
        cdef double bound
        for bound in bounds:
            y = _Py_HashDouble(bound)
            x = (x ^ y) * mult
            mult += <Py_hash_t>(82520 + 8)
        x += 97531
        return x

    @property
    def multi(self):
        return False

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured scan area"""
        cdef double center_lat = S2LatLng(self.loop.GetCentroid()).lat().degrees()
        width = get_distance(
            Location(center_lat, self.west),
            Location(center_lat, self.east), 2)
        height = get_distance(
            Location(self.south, 0),
            Location(self.north, 0), 2)
        return double_round(width * height, 0)
