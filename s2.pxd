from libcpp cimport bool

from vector3 cimport Vector3_d


cdef extern from "geometry/s2/s2.h":
    ctypedef Vector3_d S2Point

    cdef cppclass S2:
        S2Point Origin()
        bool ISUnitLength(S2Point)
        S2Point Ortho(S2Point)
        bool ApproxEquals(S2Point a, S2Point b, double max_error)
        S2Point RobustCrossProd(S2Point a, S2Point b)
        bool SimpleCCW(S2Point a, S2Point b, S2Point c)
        int RobustCCW(S2Point a, S2Point b, S2Point c)
        double Angle(S2Point a, S2Point b, S2Point c)
        double TurnAngle(S2Point a, S2Point b, S2Point c)
        double Area(S2Point a, S2Point b, S2Point c)
        double GirardArea(S2Point a, S2Point b, S2Point c)
        double SignedArea(S2Point a, S2Point b, S2Point c)
        double PlanarCentroid(S2Point a, S2Point b, S2Point c)
        double TrueCentroid(S2Point a, S2Point b, S2Point c)
