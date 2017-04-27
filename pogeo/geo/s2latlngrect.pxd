from libcpp cimport bool

from .s1angle cimport S1Angle
from .s2 cimport S2Point
from .s2cap cimport S2Cap
from .s2cell cimport S2Cell
from .s2latlng cimport S2LatLng
from .s2region cimport S2Region

cdef extern from "s2latlngrect.h" nogil:
    cdef cppclass S2LatLngRect(S2Region):
        S2LatLngRect(S2LatLng lo, S2LatLng hi)
        S2LatLngRect()
        @staticmethod
        S2LatLngRect FromCenterSize(S2LatLng center, S2LatLng size)
        @staticmethod
        S2LatLngRect FromPoint(S2LatLng p)
        @staticmethod
        S2LatLngRect FromPointPair(S2LatLng p1, S2LatLng p2)
        S1Angle lat_lo()
        S1Angle lat_hi()
        S1Angle lng_lo()
        S1Angle lng_hi()
        S2LatLng lo()
        S2LatLng hi()
        @staticmethod
        S2LatLngRect Empty()
        @staticmethod
        S2LatLngRect Full()
        bool is_valid()
        bool is_empty()
        bool is_full()
        bool is_point()
        bool is_inverted()
        S2LatLng GetVertext(int k)
        S2LatLng GetCenter()
        S2LatLng GetSize()
        double Area()
        bool Contains(S2LatLng ll)
        bool InteriorContains(S2Point p)
        bool InteriorContains(S2LatLng ll)
        bool Contains(S2LatLngRect other)
        bool InteriorContains(S2LatLngRect other)
        bool Intersects(S2LatLngRect other)
        bool Intersects(S2Cell cell)
        bool InteriorIntersects(S2LatLngRect other)
        void AddPoint(S2Point p)
        void AddPoint(S2LatLng ll)
        S2LatLng Project(S2LatLng ll)
        S1Angle GetDistance(S2LatLng p)
        bool Contains(S2Point p)

        # from S2Region
        S2Cap GetCapBound()
        bool Contains(S2Cell cell)
        bool MayIntersect(S2Cell cell)
