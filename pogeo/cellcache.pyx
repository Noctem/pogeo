# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint64_t
from libc.string cimport memcpy
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

from cython.operator cimport postincrement as incr, dereference as deref

from .array cimport array
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

    def __getstate__(self):
        cdef vector_uint64 cells
        cdef uint64_t cell
        cdef dict state = {}
        it = self.cache.begin()
        while it != self.cache.end():
            cell = deref(it).first
            cells = deref(it).second
            state[cell] = <array>cells
            incr(it)
        return state

    def __setstate__(self, dict state):
        cdef uint64_t cell
        cdef vector_uint64 cells
        for cell, cells in state.items():
            self.cache[cell] = <vector_uint64>cells

    def get_cell_ids(self, Location p):
        cdef size_t size
        cdef array cell_array
        cdef S2Point point = p.point
        cdef uint64_t cell = S2CellId.FromPoint(point).parent(S2_LEVEL).id()

        it = self.cache.find(cell)
        if it != self.cache.end():
            return <array>deref(it).second

        cdef S2Cap cap = S2Cap.FromAxisHeight(point, AXIS_HEIGHT)

        cdef vector_uint64 cells
        self.coverer.GetCellIds(cap, &cells)

        self.cache[cell] = cells

        return <array>cells
