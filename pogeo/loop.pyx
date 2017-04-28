# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport log2, pow
from libc.stdint cimport uint64_t
from libcpp.vector cimport vector

from .const cimport EARTH_RADIUS_METERS, EARTH_RADIUS_KILOMETERS
from .cpython_ cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s2 cimport S2, S2Point
from .geo.s2cellid cimport S2CellId
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
from .geo.s2regioncoverer cimport S2RegionCoverer
from .location cimport Location
from .utils cimport coords_to_s2point


cdef class Loop:
    def __cinit__(self, tuple points):
        cdef:
            double lat, lon
            vector[S2Point] v
            tuple coords

        for coords in points:
            lat, lon = coords
            v.push_back(coords_to_s2point(lat, lon))

        self.loop.Init(v)
        if not S2.SimpleCCW(v[0], v[1], v[2]):
            self.loop.Invert()

        cdef S2LatLngRect rect = self.loop.GetRectBound()
        self.south = rect.lat_lo().degrees()
        self.east = rect.lng_hi().degrees()
        self.north = rect.lat_hi().degrees()
        self.west = rect.lng_lo().degrees()

    def __bool__(self):
        return True

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

    def __contains__(self, Location loc):
        return self.loop.Contains(loc.point)

    def get_points(self, int level):
        cdef S2RegionCoverer coverer
        coverer.set_min_level(level)
        coverer.set_max_level(level)
        cdef vector[S2Point] points
        coverer.GetPoints(self.loop, &points)
        cdef size_t i, size = points.size()
        for i in range(size):
            yield Location.from_point(points.back())
            points.pop_back()

    def contains_cellid(self, uint64_t cellid):
        return self.loop.Contains(S2CellId(cellid << (63 - <int>log2(cellid))).ToPointRaw())

    def contains_token(self, str t):
        return self.loop.Contains(S2CellId.FromToken(t.encode('UTF-8')).ToPointRaw())

    def distance(self, Location loc):
        return self.loop.GetDistance(loc.point).radians() * EARTH_RADIUS_METERS

    def project(self, Location loc):
        return Location.from_point(self.loop.Project(loc.point))

    @property
    def center(self):
        return Location.from_point(self.loop.GetCentroid())

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.loop.GetArea() * pow(EARTH_RADIUS_KILOMETERS, 2)
