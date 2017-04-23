# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport int64_t, uint8_t, uint32_t

from cyrandom.cyrandom cimport uniform

from .const cimport DEG_TO_RAD, EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS, EARTH_RADIUS_MILES
from .cpylib cimport _PyTime_GetSystemClock
from .geo.s1angle cimport S1Angle
from .geo.s2latlng cimport S2LatLng
from .utils cimport double_round

try:
    from shapely.geos import lgeos
except ImportError:
    class lgeos:
        @classmethod
        def GEOSCoordSeq_create(*args):
            raise ImportError('You must have Shapely installed to use Location as a GEOS point.')


cdef class Location:
    """Simple location extension type"""
    def __cinit__(self, double latitude, double longitude, double altitude=0.0, uint32_t time=0):
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.time = time
        self.point = S2LatLng.FromDegrees(latitude, longitude).ToPoint()

    def __getstate__(self):
        return self.latitude, self.longitude, self.altitude, self.time

    def __setstate__(self, state):
        self.latitude, self.longitude, self.altitude, self.time = state
        self.point = S2LatLng.FromDegrees(self.latitude, self.longitude).ToPoint()

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

    def distance(self, Location other, char unit=3):
        cdef S1Angle angle = S1Angle(self.point, other.point)

        if unit == 1:
            return angle.radians() * EARTH_RADIUS_MILES
        elif unit == 2:
            return angle.radians() * EARTH_RADIUS_KILOMETERS
        else:
            return angle.radians() * EARTH_RADIUS_METERS

    def distance_meters(self, Location other, char unit=3):
        cdef S1Angle angle = S1Angle(self.point, other.point)
        return angle.radians() * EARTH_RADIUS_METERS

    def round(self, int precision):
        return double_round(self.latitude, precision), double_round(self.longitude, precision)

    def jitter(self, double amount=0.0003):
        self.latitude = uniform(self.latitude - amount, self.latitude + amount)
        self.longitude = uniform(self.longitude - amount, self.longitude + amount)
        self.altitude = uniform(self.altitude - 2, self.altitude + 2)

    def update_time(self):
        self.time = _PyTime_GetSystemClock() / 1000000000

    @property
    def _ndim(self):
        return 2 if self.altitude == 0.0 else 3

    @property
    def _geom(self):
        cdef uint8_t n = 2 if self.altitude == 0.0 else 3
        cdef int64_t cs = lgeos.GEOSCoordSeq_create(1, n)
        lgeos.GEOSCoordSeq_setX(cs, 0, self.latitude)
        lgeos.GEOSCoordSeq_setY(cs, 0, self.longitude)
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

    cdef double lat_radian(self):
        return self.latitude * DEG_TO_RAD

    cdef double lon_radian(self):
        return self.longitude * DEG_TO_RAD
