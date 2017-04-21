from libcpp cimport bool

from vector3 cimport Vector3_d


cdef extern from "geometry/s2/s2.h":
    ctypedef Vector3_d S2Point

    cdef cppclass S2:
        @staticmethod
        S2Point Origin()
        @staticmethod
        bool ISUnitLength(S2Point)
        @staticmethod
        S2Point Ortho(S2Point)
        @staticmethod
        bool ApproxEquals(S2Point a, S2Point b, double max_error)
        @staticmethod
        S2Point RobustCrossProd(S2Point a, S2Point b)
        @staticmethod
        bool SimpleCCW(S2Point a, S2Point b, S2Point c)
        @staticmethod
        int RobustCCW(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double Angle(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double TurnAngle(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double Area(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double GirardArea(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double SignedArea(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double PlanarCentroid(S2Point a, S2Point b, S2Point c)
        @staticmethod
        double TrueCentroid(S2Point a, S2Point b, S2Point c)
        @staticmethod
        int ClosestLevel(double value)

