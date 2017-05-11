from libcpp.vector cimport vector
from libcpp cimport bool

from .s1angle cimport S1Angle
from .s2 cimport S2Point
from .s2cap cimport S2Cap
from .s2cell cimport S2Cell
from .s2latlngrect cimport S2LatLngRect
from .s2region cimport S2Region


cdef extern from "s2loop.h" nogil:
    cdef cppclass S2Loop(S2Region):
        S2Loop()
        S2Loop(const vector[S2Point] &vertices)
        void Init(const vector[S2Point] &vertices)
        bool IsValid()
        S2Loop(S2Cell cell)
        int depth()
        void set_depth(int depth)
        bool is_hole()
        int sign()
        int num_vertices()
        S2Point vertex(int i)
        bool IsNormalized()
        void Normalize()
        void Invert()
        double GetArea()
        S2Point GetCentroid()
        double GetTurningAngle()
        bool Contains(S2Loop p)
        bool Intersects(S2Loop b)
        bool ContainsNested(S2Loop b)
        int ContainsOrCrosses(S2Loop b)
        bool BoundaryEquals(S2Loop b)
        bool BoundaryApproxEquals(S2Loop b)
        S2Point Project(S2Point point)
        S1Angle GetDistance(S2Point point)
        bool Contains(S2Point p)

        # from S2Region
        S2Loop Clone()
        S2Cap GetCapBound()
        S2LatLngRect GetRectBound()
        bool Contains(S2Cell cell)
        bool MayIntersect(S2Cell cell)
