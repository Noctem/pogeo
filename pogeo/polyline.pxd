from libcpp.string cimport string
from libcpp.vector cimport vector

from .geo.s2 cimport S2Point


cdef string encode_s2points(vector[S2Point] &points, size_t start, size_t end)
