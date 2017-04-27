# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport pow

from .const cimport EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS
from .cpython_ cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2, S2Point
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
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
        self.latlngrect = S2LatLngRect(lo, hi)
        self.unbound = not bound

    def __contains__(self, Location loc):
        return self.unbound or (
            loc.latitude >= self.south
            and loc.latitude <= self.north
            and loc.longitude >= self.west
            and loc.longitude <= self.east)

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

    def distance(self, Location loc):
        cdef S2LatLng ll = S2LatLng.FromDegrees(loc.latitude, loc.longitude)
        cdef S1Angle angle = self.latlngrect.GetDistance(ll)
        return angle.radians() * EARTH_RADIUS_METERS

    def project(self, Location loc):
        cdef S2LatLng ll = S2LatLng.FromDegrees(loc.latitude, loc.longitude)
        ll = self.latlngrect.Project(ll)
        return Location(ll.lat().degrees(), ll.lng().degrees())

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.latlngrect.Area() * pow(EARTH_RADIUS_KILOMETERS, 2)


