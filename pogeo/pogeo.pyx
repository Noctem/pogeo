# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport atan2, cos, fmod, M_PI, pow, sin, sqrt
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map
from libcpp cimport bool

from cpython.array cimport array
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython cimport bool as pybool

from cython.operator cimport dereference as deref
from cython cimport boundscheck

from cyrandom.cyrandom cimport uniform

from .cpylib cimport *
from .s2.s2 cimport S2Point, S2
from .s2.s2cap cimport S2Cap
from .s2.s2latlng cimport S2LatLng
from .s2.s1angle cimport S1Angle
from .s2.s2regioncoverer cimport S2RegionCoverer
from .s2.s2cellid cimport S2CellId
from .s2.s2loop cimport S2Loop

try:
    from shapely.geos import lgeos
except ImportError:
    class lgeos:
        @classmethod
        def GEOSCoordSeq_create(*args):
            raise ImportError('You must have Shapely installed to use Location as a GEOS point.')


cdef double EARTH_RADIUS_KILOMETERS = 6371.0088
cdef double EARTH_RADIUS_METERS = 6371008.8
cdef double EARTH_RADIUS_MILES = EARTH_RADIUS_KILOMETERS * 0.621371
cdef double AXIS_HEIGHT = pow(500 / EARTH_RADIUS_METERS, 2) / 2.0
cdef double RAD_TO_DEG = 180.0 / M_PI
cdef double DEG_TO_RAD = M_PI / 180.0


ctypedef vector[unsigned long long] vector_uint64

cpdef double double_round(double x, int ndigits):
    """Simplified version of stdlib's round function.
    """
    cdef double rounded
    cdef Py_ssize_t buflen, shortbuflen=27
    cdef char shortbuf[27]
    cdef char *buf
    cdef char *buf_end
    cdef char *mybuf = shortbuf
    cdef int decpt, sign

    # round to a decimal string
    buf = _Py_dg_dtoa(x, 3, ndigits, &decpt, &sign, &buf_end)

    buflen = buf_end - buf

    # copy buf to shortbuf, adding exponent, sign and leading 0
    PyOS_snprintf(shortbuf, shortbuflen, "%s0%se%d", "-" if sign else "",
                  buf, decpt - <int>buflen)

    # and convert the resulting string back to a double
    rounded = _Py_dg_strtod(shortbuf, NULL)

    _Py_dg_freedtoa(buf)
    return rounded


cdef class Location:
    """Simple location extension type"""
    cdef double latitude, longitude
    cdef public double altitude
    cdef readonly unsigned long time
    cdef S2Point point

    def __cinit__(self, double latitude, double longitude, double altitude=0.0, unsigned long time=0):
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
        return get_distance(self, other, unit)

    def round(self, int precision):
        return double_round(self.latitude, precision), double_round(self.longitude, precision)

    def jitter(self, double amount=0.0003):
        self.latitude = uniform(self.latitude - amount, self.latitude + amount)
        self.longitude = uniform(self.longitude - amount, self.longitude + amount)
        self.altitude = uniform(self.longitude - 2, self.longitude + 2)

    def update_time(self):
        self.time = _PyTime_GetSystemClock() / 1000000000

    @property
    def _ndim(self):
        return 2 if self.altitude == 0.0 else 3

    @property
    def _geom(self):
        cdef unsigned char n = 2 if self.altitude == 0.0 else 3
        cdef long long cs = lgeos.GEOSCoordSeq_create(1, n)
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


cpdef double get_bearing(tuple point1, tuple point2):
    cdef double lat1, lon1, lat2, lon2

    lat1, lon1 = point1
    lat2, lon2 = point2

    lat1 *= DEG_TO_RAD
    lat2 *= DEG_TO_RAD

    cdef double lon_diff = (lon2 - lon1) * DEG_TO_RAD
    cdef double x = sin(lon_diff) * cos(lat2)
    cdef double y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(lon_diff))
    cdef double initial_bearing = atan2(x, y)
    return fmod(initial_bearing * RAD_TO_DEG + 360, 360)


cpdef double get_distance(Location p1, Location p2, char unit=3):
    cdef double lat1, lon1, lat2, lon2, dlat, dlon, x

    lat1 = p1.lat_radian()
    lon1 = p1.lon_radian()
    lat2 = p2.lat_radian()
    lon2 = p2.lon_radian()

    dlat = sin(0.5 * (lat2 - lat1))
    dlon = sin(0.5 * (lon2 - lon1))

    x = pow(dlat, 2) + pow(dlon, 2) * cos(lat1) * cos(lat2)
    x = 2 * atan2(sqrt(x), sqrt(max(0.0, 1.0 - x)))

    if unit == 1:
        return x * EARTH_RADIUS_MILES
    elif unit == 2:
        return x * EARTH_RADIUS_KILOMETERS
    else:
        return x * EARTH_RADIUS_METERS


cdef class CellCache:
    cdef readonly unordered_map[unsigned long long, vector_uint64] cells
    cdef S2RegionCoverer coverer

    def __cinit__(self):
        self.coverer.set_min_level(15)
        self.coverer.set_max_level(15)

    def get_cell_ids(self, Location p):
        cdef S2Point point = p.point
        cdef unsigned long long cell = cell_id_for_s2point(point)
        it = self.cells.find(cell)
        if it != self.cells.end():
             return deref(it).second

        cdef S2Cap region = S2Cap.FromAxisHeight(point, AXIS_HEIGHT)

        cdef vector[unsigned long long] covering
        self.coverer.GetCellIds(region, &covering)
        self.cells[cell] = covering

        return covering

cpdef list get_cell_ids(tuple point):
    cdef double lat, lon
    lat, lon = point

    cdef S2Cap region = S2Cap.FromAxisHeight(
        S2LatLng.FromDegrees(lat, lon).ToPoint(),
        AXIS_HEIGHT)

    cdef S2RegionCoverer coverer
    coverer.set_min_level(15)
    coverer.set_max_level(15)

    cdef vector[unsigned long long] covering
    coverer.GetCellIds(region, &covering)

    return covering


cpdef list get_cell_ids2(tuple point):
    cdef double lat, lon
    lat, lon = point

    cdef S2Point p = S2LatLng.FromDegrees(lat, lon).ToPoint()

    cdef S2Cap region = S2Cap.FromAxisHeight(p, AXIS_HEIGHT)

    cdef S2RegionCoverer coverer

    cdef vector[unsigned long long] covering
    coverer.GetSimpleCoveringId(region, p, 15, &covering)

    return covering

#cdef array GetCovering():

cdef unsigned char closest_level(double value):
    return S2.ClosestLevel(value / EARTH_RADIUS_METERS)

def get_cell_ids_compact(tuple point):
    return array('Q', get_cell_ids(point))

cdef unsigned long long cell_id_for_s2point(S2Point p):
    return S2CellId.FromPoint(p).parent(15).id()

def cell_id_for_point(Location p):
    return S2CellId.FromPoint(p.point).parent(15).id()

cdef class Polygon:
    cdef S2Loop loop
    cdef readonly double south, east, north, west
    cdef readonly pybool multi
    cdef readonly vector[double] center

    def __cinit__(self, tuple points):
        cdef double lat, lon
        cdef vector[S2Point] v
        cdef S2Point a, b, c
        cdef unsigned short length, i

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
        width = get_distance((self.center[0], self.west), (self.center[0], self.east), 2)
        height = get_distance((self.south, 0), (self.north, 0), 2)
        return round(width * height)
