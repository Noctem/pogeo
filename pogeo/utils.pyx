# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.string cimport memmove
from libc.math cimport atan2, cos, fmod, sin
from libc.stdint cimport uint8_t, uint64_t
from libcpp.unordered_set cimport unordered_set
from libcpp.vector cimport vector

from .array cimport array, clone
from .cellcache cimport ARRAY_TEMPLATE
from .const cimport AXIS_HEIGHT, DEG_TO_RAD, EARTH_RADIUS_KILOMETERS, EARTH_RADIUS_METERS, EARTH_RADIUS_MILES, RAD_TO_DEG
from .cpylib cimport _PyTime_t, _Py_dg_dtoa, _Py_dg_strtod, _Py_dg_freedtoa, PyOS_snprintf
from .location cimport Location
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2, S2Point
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .geo.s2regioncoverer cimport S2RegionCoverer
from .types cimport vector_uint64

DEF S2_LEVEL = 15


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


cdef uint8_t closest_level(double value):
    return S2.ClosestLevel(value / EARTH_RADIUS_METERS)


def cell_id_for_point(Location p):
    return S2CellId.FromPoint(p.point).parent(S2_LEVEL).id()


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
