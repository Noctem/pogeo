from libcpp cimport bool
from libcpp.string cimport string

from .s2 cimport S2Point
from .s2latlng cimport S2LatLng
from .s2cellid cimport S2CellId


cdef extern from "s2cellid.h" nogil:
    cdef cppclass S2CellId:
        @staticmethod
        S2CellId FromPoint(S2Point p)
        @staticmethod
        S2CellId FromLatLng(S2LatLng ll)
        S2Point ToPoint()
        S2Point ToPointRaw()
        S2LatLng ToLatLng()
        unsigned long long id()
        bool is_valid()
        S2CellId parent(int level)
        string ToToken()
        string ToString()
        void GetEdgeNeighbors(S2CellId neighbors[4])
