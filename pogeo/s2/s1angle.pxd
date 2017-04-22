from .s2 cimport S2Point
from .s2latlng cimport S2LatLng


cdef extern from "s1angle.h" nogil:
    cdef cppclass S1Angle:
        @staticmethod
        S1Angle Radians(double radians)
        @staticmethod
        S1Angle Degrees(double degrees)
        S1Angle()
        S1Angle(S2Point x, S2Point y)
        S1Angle(S2LatLng x, S2LatLng y)
        double radians()
        double degrees()
        S1Angle abs()
        S1Angle Normalized()
        void Normalize()
