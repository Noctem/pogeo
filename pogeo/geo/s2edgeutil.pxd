from .s1angle cimport S1Angle
from .s2 cimport S2Point


cdef extern from "s2edgeutil.h" nogil:
    cdef cppclass S2EdgeUtil:
        @staticmethod
        double GetDistanceFraction(S2Point x, S2Point a, S2Point b)
        @staticmethod
        S2Point Interpolate(double t, S2Point a, S2Point b)
        @staticmethod
        S2Point InterpolateAtDistance(S1Angle ax, S2Point a, S2Point b)
