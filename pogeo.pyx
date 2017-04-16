# distutils: language = c++
# cython: language_level=3

from libc.math cimport atan2, cos, fmod, M_PI, pow, sin
from libcpp.vector cimport vector

from cpython.array cimport array

from s2 cimport S2Point
from s2cap cimport S2Cap
from s2latlng cimport S2LatLng
from s1angle cimport S1Angle
from s2regioncoverer cimport S2RegionCoverer
from s2cellid cimport S2CellId


cdef double EARTH_RADIUS_KILOMETERS = 6371.0088
cdef double EARTH_RADIUS_METERS = 6371008.8
cdef double EARTH_RADIUS_MILES = EARTH_RADIUS_KILOMETERS * 0.621371
cdef double AXIS_HEIGHT = pow(500 / EARTH_RADIUS_METERS, 2) / 2
cdef double RAD_TO_DEG = 180.0 / M_PI
cdef double DEG_TO_RAD = M_PI / 180.0


def get_bearing(tuple point1, tuple point2):
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


def get_distance(tuple point1, tuple point2, char unit=3):
    cdef double lat1, lon1, lat2, lon2

    lat1, lon1 = point1
    lat2, lon2 = point2

    cdef S2LatLng p1 = S2LatLng.FromDegrees(lat1, lon1)
    cdef S2LatLng p2 = S2LatLng.FromDegrees(lat2, lon2)

    cdef double rad = p1.GetDistance(p2).radians()

    if unit == 1:
        return rad * EARTH_RADIUS_MILES
    elif unit == 2:
        return rad * EARTH_RADIUS_KILOMETERS
    else:
        return rad * EARTH_RADIUS_METERS


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


def get_cell_ids_compact(tuple point):
    return array('Q', get_cell_ids(point))
