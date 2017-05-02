# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.string cimport memmove
from libc.math cimport atan2, cos, fmod, log2, sin
from libc.stdint cimport uint8_t, uint64_t
from libcpp.unordered_set cimport unordered_set
from libcpp.vector cimport vector

from .array cimport array, clone
from .const cimport AXIS_HEIGHT, DEG_TO_RAD, EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS, EARTH_RADIUS_MILES, RAD_TO_DEG
from .location cimport Location
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2, S2Point
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .geo.s2edgeutil cimport S2EdgeUtil
from .geo.s2latlng cimport S2LatLng
from .geo.s2regioncoverer cimport S2RegionCoverer
from .types cimport shape, vector_uint64

DEF S2_LEVEL = 15

cdef array ARRAY_TEMPLATE = array('Q', [])


cpdef double get_bearing(Location point1, Location point2):
    cdef double lat1, lat2, lon_diff, x, y, initial_bearing

    lat1 = point1.latitude * DEG_TO_RAD
    lat2 = point2.latitude * DEG_TO_RAD

    lon_diff = (point2.longitude - point1.longitude) * DEG_TO_RAD
    x = sin(lon_diff) * cos(lat2)
    y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(lon_diff))
    initial_bearing = atan2(x, y)
    return fmod(initial_bearing * RAD_TO_DEG + 360, 360)


cpdef double get_distance(Location p1, Location p2, char unit=3):
    cdef S1Angle angle = S1Angle(p1.point, p2.point)

    if unit == 1:
        return angle.radians() * EARTH_RADIUS_MILES
    elif unit == 2:
        return angle.radians() * EARTH_RADIUS_KILOMETERS
    else:
        return angle.radians() * EARTH_RADIUS_METERS


def get_distance_meters(Location p1, Location p2):
    cdef S1Angle angle = S1Angle(p1.point, p2.point)
    return angle.radians() * EARTH_RADIUS_METERS


def distance_to_latlon(Location p, double distance):
    cdef double r = distance / EARTH_RADIUS_METERS
    cdef S1Angle a = S1Angle.Radians(r)
    cdef double additive = 1.0 if p.latitude < 89.0 else -1.0
    cdef S2Point dest = coords_to_s2point(p.latitude + additive, p.longitude)
    cdef S2Point s = S2EdgeUtil.InterpolateAtDistance(a, p.point, dest)
    cdef S2LatLng ll = S2LatLng(s)
    cdef double latdiff = ll.lat().degrees() - p.latitude
    additive = 1.0 if p.longitude < 189.0 else -1.0
    dest = coords_to_s2point(p.latitude, p.longitude + additive)
    s = S2EdgeUtil.InterpolateAtDistance(a, p.point, dest)
    ll = S2LatLng(s)
    cdef double londiff = ll.lng().degrees() - p.longitude
    return latdiff, londiff


def diagonal_distance(Location p, double distance):
    cdef double r = distance / EARTH_RADIUS_METERS
    cdef S1Angle a = S1Angle.Radians(r)
    cdef double lat_add = 10.0 if p.latitude < 80.0 else -10.0
    cdef double lon_add = 10.0 if p.longitude < 180.0 else -10.0
    cdef S2Point dest = coords_to_s2point(p.latitude + lat_add, p.longitude + lon_add)
    cdef S2Point s = S2EdgeUtil.InterpolateAtDistance(a, p.point, dest)
    cdef S2LatLng ll = S2LatLng(s)
    return ll.lat().degrees() - p.latitude, ll.lng().degrees() - p.longitude


def get_cell_ids(Location p):
    cdef S2Cap cap = S2Cap.FromAxisHeight(p.point, AXIS_HEIGHT)

    cdef S2RegionCoverer coverer
    coverer.set_min_level(S2_LEVEL)
    coverer.set_max_level(S2_LEVEL)

    cdef vector_uint64 cells
    coverer.GetCellIds(cap, &cells)
    cdef size_t size = cells.size()
    cdef array cell_array = clone(ARRAY_TEMPLATE, size)
    memmove(&cell_array.data.as_ulonglongs[0], &cells[0], size * 8)
    return cell_array


cdef vector[S2Point] get_s2points(shape bounds, int level):
    cdef S2RegionCoverer coverer
    coverer.set_min_level(level)
    coverer.set_max_level(level)
    cdef vector[S2Point] points
    coverer.GetPoints(bounds.shape, &points)
    return points

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
    return Location.from_point(S2CellId(cellid << (63 - <int>log2(cellid))).ToPointRaw())


def token_to_location(str t):
    return Location.from_point(S2CellId.FromToken(t.encode('UTF-8')).ToPointRaw())


def location_to_cellid(Location p):
    return S2CellId.FromPoint(p.point).parent(S2_LEVEL).id()


cdef S2Point coords_to_s2point(double lat, double lon):
    return S2LatLng.FromDegrees(lat, lon).ToPoint()