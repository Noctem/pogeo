# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport atan2, sqrt
from libc.stdint cimport int64_t, uint8_t

from cyrandom.cyrandom cimport uniform

from .const cimport DEG_TO_RAD, EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS, EARTH_RADIUS_MILES
from .cpython_ cimport _PyTime_GetSystemClock
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2Point
from .geo.s2latlng cimport S2LatLng
from .libcpp_ cimport max
from .utils cimport coords_to_s2point, get_distance, get_distance_unit, s2point_to_lat, s2point_to_lon

try:
    from shapely.geos import lgeos
except ImportError:
    class lgeos:
        @classmethod
        def GEOSCoordSeq_create(*args):
            raise ImportError('You must have Shapely installed to use Location as a GEOS point.')


cdef class Location:
    """Simple location extension type"""
    def __cinit__(self, double latitude, double longitude):
        self.latitude = latitude
        self.longitude = longitude

    def __init__(self, double latitude, double longitude):
        self.point = coords_to_s2point(latitude, longitude)

    def __getnewargs__(self):
        return self.latitude, self.longitude

    def __getstate__(self):
        cdef double[3] point = self.point.Data()
        return self.altitude, self.time, <tuple>point

    def __setstate__(self, tuple state):
        cdef tuple point
        self.altitude, self.time, point = state
        self.point = S2Point(point[0], point[1], point[2])

    def __getitem__(self, char key):
        if key == 0 or key == -3:
            return self.latitude
        elif key == 1 or key == -2:
            return self.longitude
        elif key == 2 or key == -1:
            return self.altitude
        else:
            raise IndexError('Must be 0, 1, or 2.')

    def __setitem__(self, char key, double value):
        if key == 0 or key == -3:
            self.latitude = value
        elif key == 1 or key == -2:
            self.longitude = value
        elif key == 2 or key == -1:
            self.altitude = value
        else:
            raise IndexError('Must be 0, 1, or 2.')

    def __repr__(self):
        return "Location(%r, %r, %r)" % (self.latitude, self.longitude, self.altitude)

    def __str__(self):
        return "Location(%f, %f, %f)" % (self.latitude, self.longitude, self.altitude)

    def __len__(self):
        return 2 if self.altitude == 0.0 else 3

    def __iter__(self):
        return iter((self.latitude, self.longitude, self.altitude))

    def distance(self, Location other):
        return get_distance(self, other)

    def distance_unit(self, Location other, char unit=3):
        return get_distance_unit(self, other, unit)

    def speed(self, Location other):
        cdef double time_diff = _PyTime_GetSystemClock() / 1000000000 - self.time
        return S1Angle(self.point, other.point).radians() * EARTH_RADIUS_METERS / time_diff

    def speed_with_time(self, Location other, double current_time):
        cdef double time_diff = max[double](current_time - self.time, 10.0)
        return S1Angle(self.point, other.point).radians() * EARTH_RADIUS_METERS / time_diff

    def jitter(self, double lat_amount, double lon_amount, double alt_amount=2.0):
        self.latitude = uniform(self.latitude - lat_amount, self.latitude + lat_amount)
        self.longitude = uniform(self.longitude - lon_amount, self.longitude + lon_amount)
        if self.altitude:
            self.altitude = uniform(self.altitude - alt_amount, self.altitude + alt_amount)

    def update_time(self):
        self.time = _PyTime_GetSystemClock() // 1000000000

    @staticmethod
    cdef Location from_point(S2Point p):
        cdef Location loc = Location.__new__(Location,
            s2point_to_lat(p),
            s2point_to_lon(p))
        loc.point = p
        return loc

    @property
    def _ndim(self):
        return 2 if self.altitude == 0.0 else 3

    @property
    def _geom(self):
        cdef uint8_t n = 2 if self.altitude == 0.0 else 3
        cdef int64_t cs = lgeos.GEOSCoordSeq_create(1, n)
        lgeos.GEOSCoordSeq_setX(cs, 0, self.longitude)
        lgeos.GEOSCoordSeq_setY(cs, 0, self.latitude)
        if n == 3:
            lgeos.GEOSCoordSeq_setZ(cs, 0, self.altitude)
        return lgeos.GEOSGeom_createPoint(cs)

    @property
    def type(self):
        return 'Point'

    @property
    def coords(self):
        """A tuple of latitude and longitude"""
        return self.latitude, self.longitude

    @coords.setter
    def coords(self, tuple coords):
        self.latitude, self.longitude = coords

    @property
    def location(self):
        """A tuple of latitude, longitude, altitude"""
        return self.latitude, self.longitude, self.altitude

    @location.setter
    def location(self, tuple location):
        self.latitude, self.longitude, self.altitude = location
