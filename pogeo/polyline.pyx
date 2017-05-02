# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport round
from libcpp.string cimport string
from libcpp.vector cimport vector

from .geo.s2 cimport S2Point
from .geo.s2latlng cimport S2LatLng
from .location cimport Location


cdef void write(string &output, double curr, double prev):
    cdef long curr_value = <long>(round(curr * 100000.0) - round(prev * 100000.0))
    curr_value <<= 1
    if curr_value < 0:
        curr_value = ~curr_value
    while curr_value >= 0x20:
        output.push_back((0x20 | (curr_value & 0x1f)) + 63)
        curr_value >>= 5
    output.push_back(curr_value + 63)


def encode_single(Location loc):
    cdef string output
    write(output, loc.latitude, 0.0)
    write(output, loc.longitude, 0.0)
    return output


def encode_multiple(tuple points):
    cdef:
        string output
        Location curr_loc, prev_loc
        size_t i, size = len(points)
    curr_loc = points[0]
    write(output, curr_loc.latitude, 0.0)
    write(output, curr_loc.longitude, 0.0)
    for i in range(1, size):
        prev_loc = curr_loc
        curr_loc = points[i]
        write(output, curr_loc.latitude, prev_loc.latitude)
        write(output, curr_loc.longitude, prev_loc.longitude)
    return output

cdef string encode_s2points(vector[S2Point] &points, size_t start, size_t end):
    cdef:
        S2LatLng prev, curr
        size_t i
        string output = string(<char *>"enc:")
    curr = S2LatLng(points[start])
    write(output, curr.lat().degrees(), 0.0)
    write(output, curr.lng().degrees(), 0.0)
    for i in range(start + 1, end):
        prev = curr
        curr = S2LatLng(points[i])
        write(output, curr.lat().degrees(), prev.lat().degrees())
        write(output, curr.lng().degrees(), prev.lng().degrees())
    return output
