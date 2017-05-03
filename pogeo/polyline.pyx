# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport round
from libc.stdint cimport int32_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from .geo.s2 cimport S2Point
from .geo.s2latlng cimport S2LatLng
from .location cimport Location


cdef void write(string &output, int32_t val, int32_t prev):
    val -= prev
    val = ~(val << 1) if val < 0 else val << 1
    while val >= 0x20:
        output.push_back((0x20 | (val & 0x1f)) + 63)
        val >>= 5
    output.push_back(val + 63)


def encode_single(Location loc):
    cdef string output
    write(output, <int32_t>round(loc.latitude * 100000.0), 0)
    write(output, <int32_t>round(loc.longitude * 100000.0), 0)
    return output


def encode_multiple(tuple points):
    cdef:
        string output
        int32_t curr_lat, curr_lon, prev_lat, prev_lon
        Location loc
        size_t i, size = len(points)
    curr_lat = curr_lon = 0
    for i in range(size):
        loc = points[i]
        prev_lat = curr_lat
        curr_lat = <int32_t>round(loc.latitude * 100000.0)
        write(output, curr_lat, prev_lat)
        prev_lon = curr_lon
        curr_lon = <int32_t>round(loc.longitude * 100000.0)
        write(output, curr_lon, prev_lon)
    return output


cdef string encode_s2points(vector[S2Point] &points, size_t start, size_t end):
    cdef:
        string output
        int32_t curr_lat, curr_lon, prev_lat, prev_lon
        S2LatLng ll
        size_t i
    curr_lat = curr_lon = 0
    for i in range(start, end):
        ll = S2LatLng(points[i])
        prev_lat = curr_lat
        curr_lat = <int32_t>round(ll.lat().degrees() * 100000.0)
        write(output, curr_lat, prev_lat)
        prev_lon = curr_lon
        curr_lon = <int32_t>round(ll.lng().degrees() * 100000.0)
        write(output, curr_lon, prev_lon)
    return output
