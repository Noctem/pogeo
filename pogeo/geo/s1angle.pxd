from libc.stdint cimport int32_t

from .s2 cimport S2Point
from .s2latlng cimport S2LatLng


cdef extern from "s1angle.h" nogil:
    cdef cppclass S1Angle:
        S1Angle(S2Point x, S2Point y)
        S1Angle()
        @staticmethod
        S1Angle Radians(double radians)
        @staticmethod
        S1Angle Degrees(double degrees)
        S1Angle(S2LatLng x, S2LatLng y)
        double radians()
        double degrees()
        int32_t e5()
        int32_t e6()
        int32_t e7()
        S1Angle abs()
        S1Angle Normalized()
        void Normalize()
