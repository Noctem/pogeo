from libcpp cimport bool

from .s1angle cimport S1Angle
from .s2 cimport S2Point
from .s2cell cimport S2Cell
from .s2latlngrect cimport S2LatLngRect
from .s2region cimport S2Region


cdef extern from "s2cap.h" nogil:
    cdef cppclass S2Cap(S2Region):
        S2Cap()
        @staticmethod
        S2Cap FromAxisHeight(S2Point axis, double height)
        @staticmethod
        S2Cap FromAxisAngle(S2Point axis, S1Angle angle)
        @staticmethod
        S2Cap FromAxisArea(S2Point axis, double area)
        @staticmethod
        S2Cap Empty()
        @staticmethod
        S2Cap Full()
        S2Point axis()
        double height()
        double area()
        S1Angle angle()
        bool is_valid()
        bool is_empty()
        bool is_full()
        S2Cap Complement()
        bool Contains(S2Cap other)
        bool Intersects(S2Cap other)
        bool InteriorIntersects(S2Cap other)
        bool InteriorContains(S2Cap other)
        void AddPoint(S2Point p)
        void AddCap(S2Cap other)
        S2Cap Expanded(S1Angle distance)
        bool MayIntersect(S2Cell cell)
        bool Contains(S2Point p)

        # from S2Region
        S2LatLngRect GetRectBound()
        bool Contains(S2Cell cell)
        bool MayIntersect(S2Cell cell)
        bool VirtualContainsPoint(S2Point p)