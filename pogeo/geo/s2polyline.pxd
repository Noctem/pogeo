from libcpp cimport bool
from libcpp.vector cimport vector

from .s1angle cimport S1Angle
from .s2 cimport S2Point
from .s2latlng cimport S2LatLng
from .s2region cimport S2Region

cdef extern from "s2polyline.h" nogil:
    cdef cppclass S2Polyline(S2Region):
        S2Polyline()
        S2Polyline(vector[S2Point] vertices)
        S2Polyline(vector[S2LatLng] vertices)
        void Init(vector[S2Point] vertices)
        void Init(vector[S2LatLng] vertices)
        @staticmethod
        bool IsValid(vector[S2Point] vertices)
        int num_vertices()
        S2Point vertex(int k)
        S1Angle GetLength()
        S2Point GetCentroid()
        S2Point Interpolate(double fraction)
        S2Point GetSuffix(double fraction, int* next_vertex)
        double UnInterpolate(S2Point point, int next_vertex)
        S2Point Project(S2Point point, int* next_vertex)
        bool IsOnRight(S2Point point)
        bool Intersects(S2Polyline* line)
        void Reverse()
        void SubsampleVertices(S1Angle tolerance, vector[int]* indices)
        bool ApproxEquals(S2Polyline* b, double max_error)
        bool NearlyCoversPolyline(S2Polyline covered, S1Angle max_error)

        # from S2Region
        S2Polyline* Clone()

        bool VirtualContainsPoint(S2Point p)
