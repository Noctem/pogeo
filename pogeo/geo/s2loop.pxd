from libcpp.vector cimport vector
from libcpp cimport bool

from .s2 cimport S2Point
from .s2cap cimport S2Cap
from .s2cell cimport S2Cell
from .s2region cimport S2Region


cdef extern from "s2loop.h" nogil:
    cdef cppclass S2Loop(S2Region):
        S2Loop()
        S2Looop(const vector[S2Point] &vertices)
        void Init(const vector[S2Point] &vertices)
        bool IsValid()
        S2Loop(S2Cell cell)
        int depth()
        void set_depth(int depth)
        bool is_hole()
        int sign()
        int num_vertices()
        bool IsNormalized()
        void Normalize()
        void Invert()
        double GetArea()
        S2Point GetCentroid()
        double GetTurningAngle()
        bool Contains(S2Point p)
        bool Intersects(S2Loop b)
        bool ContainsNested(S2Loop b)
        int ContainsOrCrosses(S2Loop b)
        bool BoundaryEquals(S2Loop b)
        bool BOundaryApproxEquals(S2Loop b)
        S2Cap GetCapBound()
