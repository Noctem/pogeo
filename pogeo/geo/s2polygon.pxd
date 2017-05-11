from libcpp.vector cimport vector
from libcpp cimport bool

from .s1angle cimport S1Angle
from .s2 cimport S2Point
from .s2cap cimport S2Cap
from .s2cell cimport S2Cell
from .s2latlngrect cimport S2LatLngRect
from .s2loop cimport S2Loop
from .s2region cimport S2Region


cdef extern from "s2polygon.h" nogil:
    cdef cppclass S2Polygon(S2Region):
        S2Polygon()
        S2Polygon(vector[S2Loop*]* loops)
        S2Polygon(S2Cell cell)
        void Init(vector[S2Loop*]* loops)
        void Release(vector[S2Loop*]* loops)
        void Copy(S2Polygon src)
        @staticmethod
        bool IsValid(vector[S2Loop*]& loops)
        bool IsValid()
        bool IsValid(bool check_loops, int max_adjacent)
        int num_loops()
        int num_vertices()
        S2Loop* loop(int k)
        int GetParent(int k)
        int GetLastDescendant(int k)
        double GetArea()
        S2Point GetCentroid()
        bool Contains(S2Polygon b)
        bool ApproxContains(S2Polygon b, S1Angle vertex_merge_radius)
        bool Intersects(S2Polygon b)
        S2Point Project(S2Point point)
        S1Angle GetDistance(S2Point point)
        bool Contains(S2Point p)

        # from S2Region
        S2Cap GetCapBound()
        S2LatLngRect GetRectBound()
        bool Contains(S2Cell cell)
        bool MayIntersect(S2Cell cell)
