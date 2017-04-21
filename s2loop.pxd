from libcpp.vector cimport vector
from libcpp cimport bool

from s2 cimport S2Point
from s2region cimport S2Region


cdef extern from "geometry/s2/s2loop.h":
    cdef cppclass S2Loop(S2Region):
        S2Loop()
        S2Looop(const vector[S2Point] &vertices)
        void Init(const vector[S2Point] &vertices)
        bool IsValid()
        bool is_hole()
        int sign()
        int num_vertices()
        bool IsNormalized()
        void Normalize()
        void Invert()
        double GetArea()
        S2Point GetCentroid()
        bool Contains(S2Point p)
