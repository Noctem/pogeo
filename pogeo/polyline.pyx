from libc.math cimport round
from libcpp.string cimport string

from .location cimport Location


cdef void write(string* output, double curr, double prev):
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
    write(&output, loc.latitude, 0.0)
    write(&output, loc.longitude, 0.0)
    return output


def encode_multiple(tuple points):
    cdef:
        string output
        Location curr_loc, prev_loc
        size_t i, size = len(points)
    curr_loc = points[0]
    write(&output, curr_loc.latitude, 0.0)
    write(&output, curr_loc.longitude, 0.0)
    for i in range(1, size):
        prev_loc = points[i - 1]
        curr_loc = points[i]
        write(&output, curr_loc.latitude, prev_loc.latitude)
        write(&output, curr_loc.longitude, prev_loc.longitude)
    return output
