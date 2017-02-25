from libc.stdint cimport uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from .s2 cimport S2Point
from .s2cellid cimport S2CellId
from .s2latlng cimport S2LatLng
from .vector2 cimport Vector2_d


cdef extern from "s2cellid.h" nogil:
    cdef cppclass S2CellId:
        S2CellId(uint64_t)
        S2CellId()
        @staticmethod
        FromFacePosLevel(int face, uint64_t pos, int level)
        @staticmethod
        S2CellId FromPoint(S2Point p)
        @staticmethod
        S2CellId FromLatLng(S2LatLng ll)
        S2Point ToPoint()
        S2Point ToPointRaw()
        S2LatLng ToLatLng()
        Vector2_d GetCenterST()
        Vector2_d GetCenterUV()
        uint64_t id()
        bool is_valid()
        int face()
        uint64_t pos()
        int level()
        int GetSizeIJ()
        double GetSizeST()
        @staticmethod
        int getSizeIJ(int level)
        @staticmethod
        double GetSizeSt(int level)
        bool is_leaf()
        bool is_face()
        int child_position(int level)
        S2CellId range_min()
        S2CellId range_max
        bool contains(S2CellId other)
        bool intersects(S2CellId other)
        S2CellId parent()
        S2CellId parent(int level)
        S2CellId child(int position)
        string ToToken()
        @staticmethod
        S2CellId FromToken(string token)
        string ToString()
        void GetEdgeNeighbors(S2CellId neighbors[4])
