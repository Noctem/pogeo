# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint16_t
from libcpp cimport bool
from libcpp.vector cimport vector

from .geo.s2 cimport S2, S2Point
from .geo.s2latlng cimport S2LatLng
from .location cimport Location
from .utils cimport double_round, get_distance


cdef class Polygon:
    def __cinit__(self, tuple points):
        cdef double lat, lon
        cdef vector[S2Point] v
        cdef S2Point a, b, c
        cdef uint16_t length, i

        length = len(points)

        if length < 3:
            raise ValueError('Must provide at least 3 points.')

        self.multi = False

        lat, lon = points[0]
        self.south = self.north = lat
        self.east = self.west = lon
        v.push_back(S2LatLng.FromDegrees(lat, lon).ToPoint())

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
            v.push_back(S2LatLng.FromDegrees(lat, lon).ToPoint())

        self.loop.Init(v)
        a = v[0]
        b = v[1]
        c = v[2]
        cdef bool ccw = S2.SimpleCCW(a, b, c)
        if not ccw:
            self.loop.Invert()

        cdef S2LatLng ll = S2LatLng(self.loop.GetCentroid())
        self.center.push_back(ll.lat().degrees())
        self.center.push_back(ll.lng().degrees())

    def __contains__(self, Location point):
        cdef S2Point p
        p = point.point
        return self.loop.Contains(p)

    def __hash__(self):
        return hash((self.south, self.west, self.north, self.east))

    @property
    def bounds(self):
        return self.south, self.west, self.north, self.east

    @property
    def area(self):
        """Returns the square kilometers for configured scan area"""
        width = get_distance(
            Location(self.center[0], self.west),
            Location(self.center[0], self.east), 2)
        height = get_distance(
            Location(self.south, 0),
            Location(self.north, 0), 2)
        return double_round(width * height, 0)
