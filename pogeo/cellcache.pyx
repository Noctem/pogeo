# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint64_t
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

from cython.operator cimport dereference as deref

from .const cimport AXIS_HEIGHT
from .geo.s2 cimport S2Point
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .location cimport Location
from .types cimport vector_uint64


DEF S2_LEVEL = 15


cdef class CellCache:
    def __cinit__(self):
        self.coverer.set_min_level(S2_LEVEL)
        self.coverer.set_max_level(S2_LEVEL)

    def get_cell_ids(self, Location p):
        cdef S2Point point = p.point
        cdef uint64_t cell = S2CellId.FromPoint(point).parent(S2_LEVEL).id()

        it = self.cache.find(cell)
        if it != self.cache.end():
             return deref(it).second

        cdef S2Cap cap = S2Cap.FromAxisHeight(point, AXIS_HEIGHT)

        cdef vector_uint64 cells
        self.coverer.GetCellIds(cap, &cells)
        self.cache[cell] = cells

        return cells
