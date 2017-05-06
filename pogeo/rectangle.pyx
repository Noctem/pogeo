# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=ascii

from libc.math cimport log2, pow
from libc.stdint cimport uint64_t
from libcpp.vector cimport vector

from .const cimport EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS
from .cpython_ cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s2 cimport S2Point
from .geo.s2cellid cimport S2CellId
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
from .geo.s2regioncoverer cimport S2RegionCoverer
from .location cimport Location


cdef class Rectangle:
    def __cinit__(self, tuple point1, tuple point2, bint bound=True):
        cdef:
            double lat1, lat2, lon1, lon2
            S2LatLng lo, hi
        lat1, lon1 = point1
        lat2, lon2 = point2
        if lat1 > lat2:
            self.north = lat1
            self.south = lat2
        else:
            self.south = lat1
            self.north = lat2
        if lon1 > lon2:
            self.east = lon1
            self.west = lon2
        else:
            self.west = lon1
            self.east = lon2
        lo = S2LatLng.FromDegrees(self.south, self.west)
        hi = S2LatLng.FromDegrees(self.north, self.east)
        self.shape = S2LatLngRect(lo, hi)
        self.unbound = not bound

    def __bool__(self):
        return not self.unbound

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
        return x + 97531

    def __contains__(self, Location loc):
        return self.unbound or (
            loc.latitude >= self.south
            and loc.latitude <= self.north
            and loc.longitude >= self.west
            and loc.longitude <= self.east)

    def get_points(self, int level):
        cdef S2RegionCoverer coverer
        coverer.set_min_level(level)
        coverer.set_max_level(level)
        cdef vector[S2Point] points
        coverer.GetPoints(self.shape, &points)
        cdef size_t i, size = points.size()
        for i in range(size):
            yield Location.from_point(points.back())
            points.pop_back()

    def contains_cellid(self, uint64_t cellid):
        if self.unbound:
            return True
        return self.shape.Contains(S2CellId(cellid << (63 - <int>log2(cellid))).ToLatLng())

    def contains_token(self, unicode t):
        if self.unbound:
            return True
        return self.shape.Contains(S2CellId.FromToken(t).ToLatLng())

    def distance(self, Location loc):
        return self.shape.GetDistance(S2LatLng.FromDegrees(loc.latitude, loc.longitude)).radians() * EARTH_RADIUS_METERS

    def project(self, Location loc):
        cdef S2LatLng ll = S2LatLng.FromDegrees(loc.latitude, loc.longitude)
        ll = self.shape.Project(ll)
        return Location(ll.lat().degrees(), ll.lng().degrees())

    @property
    def center(self):
        return Location(
            (self.north + self.south) / 2.0,
            (self.west + self.east) / 2.0)

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.shape.Area() * pow(EARTH_RADIUS_KILOMETERS, 2)


