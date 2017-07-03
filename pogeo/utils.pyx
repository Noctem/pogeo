# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=ascii

from libc.string cimport memmove
from libc.math cimport atan2, cos, fmod, log2, sin, sqrt
from libc.stdint cimport uint32_t, uint64_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from cpython.array cimport array, clone

from ._bitscan cimport leadingZeros, trailingZeros
from ._cpython cimport _PyTime_GetSystemClock, _PyTime_GetMonotonicClock
from .const cimport AXIS_HEIGHT, DEG_TO_RAD, EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS, EARTH_RADIUS_MILES, RAD_TO_DEG
from .location cimport Location
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2, S2Point
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .geo.s2edgeutil cimport S2EdgeUtil
from .geo.s2regioncoverer cimport S2RegionCoverer
from .types cimport shape


DEF S2_LEVEL = 15

cdef array ARRAY_TEMPLATE = array('Q', [])


def distance_to_latlon(Location loc, double distance):
    cdef:
        S1Angle angle
        double additive
        S2Point point
        double latdiff, londiff

    angle = S1Angle.Radians(distance / EARTH_RADIUS_METERS)

    additive = 10.0 if loc.latitude < 80.0 else -10.0
    point = S2EdgeUtil.InterpolateAtDistance(angle, loc.point, coords_to_s2point(loc.latitude + additive, loc.longitude))
    latdiff = s2point_to_lat(point) - loc.latitude

    additive = 10.0 if loc.longitude < 180.0 else -10.0
    point = S2EdgeUtil.InterpolateAtDistance(angle, loc.point, coords_to_s2point(loc.latitude, loc.longitude + additive))
    londiff = s2point_to_lon(point) - loc.longitude

    return latdiff, londiff


def diagonal_distance(Location loc, double distance):
    cdef:
        double lat_add, lon_add
        S2Point point

    lat_add = 10.0 if loc.latitude < 80.0 else -10.0
    lon_add = 10.0 if loc.longitude < 180.0 else -10.0
    point = S2EdgeUtil.InterpolateAtDistance(
        S1Angle.Radians(distance / EARTH_RADIUS_METERS),
        loc.point,
        coords_to_s2point(loc.latitude + lat_add, loc.longitude + lon_add))
    return s2point_to_lat(point) - loc.latitude, s2point_to_lon(point) - loc.longitude


def get_cell_ids(Location p):
    cdef:
        S2Cap cap
        S2RegionCoverer coverer
        vector[uint64_t] cells
        size_t size
        array cell_array

    cap = S2Cap.FromAxisHeight(p.point, AXIS_HEIGHT)

    coverer.set_min_level(S2_LEVEL)
    coverer.set_max_level(S2_LEVEL)

    coverer.GetCellIds(cap, &cells)
    size = cells.size()
    cell_array = clone(ARRAY_TEMPLATE, size, 0)
    memmove(&cell_array.data.as_ulonglongs[0], &cells[0], size * sizeof(uint64_t))
    return cell_array


def closest_level_width(double value):
    return S2.ClosestLevelWidth(value / EARTH_RADIUS_METERS)


def closest_level_edge(double value):
    return S2.ClosestLevelEdge(value / EARTH_RADIUS_METERS)


def closest_level_area(double value):
    return S2.ClosestLevelArea(value / pow(EARTH_RADIUS_METERS, 2))


def level_width(int level):
    return S2.LevelWidth(level) * EARTH_RADIUS_METERS


def level_edge(int level):
    return S2.LevelEdge(level) * EARTH_RADIUS_METERS


def level_area(int level):
    return S2.LevelArea(level) * pow(EARTH_RADIUS_METERS, 2)


def cellid_to_location(uint64_t cellid):
    return Location.from_point(S2CellId(cellid << leadingZeros(cellid)).ToPointRaw())


def cellid_to_coords(uint64_t cellid):
    cdef S2Point p = S2CellId(cellid << leadingZeros(cellid)).ToPointRaw()
    return s2point_to_lat(p), s2point_to_lon(p)


def token_to_location(unicode t):
    return Location.from_point(S2CellId.FromToken(t).ToPointRaw())


def token_to_coords(unicode t):
    cdef S2Point p = S2CellId.FromToken(t).ToPointRaw()
    return s2point_to_lat(p), s2point_to_lon(p)


def location_to_cellid(Location p, int level=S2_LEVEL, strip_trailing=True):
    cdef uint64_t cellid = S2CellId.FromPoint(p.point).parent(level).id()
    return cellid >> trailingZeros(cellid) if strip_trailing else cellid


def location_to_token(Location p, int level=S2_LEVEL):
    return S2CellId.FromPoint(p.point).parent(level).ToToken()


cdef S2Point cellid_to_s2point(uint64_t cellid):
    return S2CellId(cellid << leadingZeros(cellid)).ToPointRaw()


cdef S2Point token_to_s2point(string token):
    return S2CellId.FromToken(token).ToPointRaw()


cpdef double get_bearing(Location point1, Location point2):
    cdef double lat1, lat2, lon_diff, x, y, initial_bearing

    lat1 = point1.latitude * DEG_TO_RAD
    lat2 = point2.latitude * DEG_TO_RAD

    lon_diff = (point2.longitude - point1.longitude) * DEG_TO_RAD
    x = sin(lon_diff) * cos(lat2)
    y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(lon_diff))
    initial_bearing = atan2(x, y)
    return fmod(initial_bearing * RAD_TO_DEG + 360, 360)


cpdef double get_distance(Location p1, Location p2):
    return S1Angle(p1.point, p2.point).radians() * EARTH_RADIUS_METERS


cpdef double get_distance_unit(Location p1, Location p2, char unit):
    if unit == 1:
        radius = EARTH_RADIUS_MILES
    elif unit == 2:
        radius = EARTH_RADIUS_KILOMETERS
    else:
        radius = EARTH_RADIUS_METERS
    return S1Angle(p1.point, p2.point).radians() * radius


cdef vector[S2Point] get_s2points(shape bounds, int level):
    cdef S2RegionCoverer coverer
    coverer.set_min_level(level)
    coverer.set_max_level(level)
    cdef vector[S2Point] points
    coverer.GetPoints(bounds.shape, &points)
    return points


cdef float monotonic():
    return _PyTime_GetMonotonicClock() / 1000000000.0


cdef float float_time():
    return _PyTime_GetSystemClock() / 1000000000.0


cdef uint32_t int_time():
    return _PyTime_GetSystemClock() // 1000000000


cdef double s2point_to_lat(S2Point p):
    return atan2(p[2], sqrt(p[0]*p[0] + p[1]*p[1])) * RAD_TO_DEG


cdef double s2point_to_lon(S2Point p):
    return atan2(p[1], p[0]) * RAD_TO_DEG


cdef S2Point coords_to_s2point(double lat, double lon):
    lat *= DEG_TO_RAD
    lon *= DEG_TO_RAD
    cdef double cos_lat = cos(lat)
    return S2Point(cos(lon) * cos_lat, sin(lon) * cos_lat, sin(lat))
