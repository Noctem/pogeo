from libc.stdint cimport uint64_t
from libcpp cimport bool

from .s2 cimport S2Point
from .s2cellid cimport S2CellId
from .s2latlng cimport S2LatLng
from .s2region cimport S2Region


cdef extern from "s2cell.h" nogil:
    cdef cppclass S2Cell(S2Region):
        S2Cell(S2CellId id)
        @staticmethod
        FromFacePosLevel(int face, uint64_t pos, int level)
        S2Cell(S2Point p)
        S2Cell(S2LatLng p)
        S2CellId id()
        int face()
        int level()
        int orientation()
        bool is_leaf()
        int GetSizeIJ()
        double GetSizeST()
        S2Point GetVertex(int k)
        S2Point GetVertexRaw(int k)
        S2Point GetEdge(int k)
        S2Point GetEdgeRaw(int k)
        bool Subdivide(S2Cell children[4])
        S2Point GetCenter()
        S2Point GetCenterRaw()
        @staticmethod
        double AverageArea(int level)
        double AverageArea()
        double ApproxArea()
        double ExactArea()
