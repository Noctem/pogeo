from libc.stdint cimport uint64_t
from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector

from .loop cimport Loop
from .polygon cimport Polygon
from .rectangle cimport Rectangle

ctypedef unordered_map[uint64_t, vector[uint64_t]] cell_map
ctypedef fused shape:
    Loop
    Polygon
    Rectangle
