from libcpp cimport bool


from s2 cimport S2Point
from s2latlng cimport S2LatLng
from s2cellid cimport S2CellId


cdef extern from "geometry/s2/s2cellid.h":
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
