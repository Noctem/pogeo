from libcpp cimport bool
from libcpp.string cimport string

from .s2 cimport S2Point
from .s1angle cimport S1Angle


cdef extern from "s2latlng.h" nogil:
    cdef cppclass S2LatLng:
        S2LatLng(S1Angle lat, S1Angle lng)
        S2LatLng()
        S2LatLng(S2Point p)
        @staticmethod
        S2LatLng Invalid()
        @staticmethod
        S2LatLng FromRadians(double lat_radians, double lng_radians)
        @staticmethod
        S2LatLng FromDegrees(double lat_degrees, double lng_degrees)
        @staticmethod
        S1Angle Latitude(S2Point p)
        @staticmethod
        S1Angle Longitude(S2Point p)
        S1Angle lat()
        S1Angle lng()
        bool is_valid()
        S2LatLng Normalized()
        S2Point ToPoint()
        S1Angle GetDistance(S2LatLng o)
        string ToStringInDegrees()
