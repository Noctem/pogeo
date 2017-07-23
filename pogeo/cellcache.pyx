# distutils: language = c++
# cython: language_level=3, cdivision=True, auto_pickle=False

from libc.stdint cimport uint64_t
from libc.string cimport memmove
from libcpp.vector cimport vector

from cython.operator cimport postincrement as incr, dereference as deref

from cpython.array cimport array, clone

from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .location cimport Location
from .utils cimport ARRAY_TEMPLATE

DEF S2_LEVEL = 15


include "const.pxi"


cdef class CellCache:
    def __cinit__(self):
        self.coverer.set_min_level(S2_LEVEL)
        self.coverer.set_max_level(S2_LEVEL)

    def __len__(self):
        return self.cache.size()

    def __getstate__(self):
        cdef:
            uint64_t cell
            vector[uint64_t] cells
            array cell_array
            size_t size
            dict state = {}

        it = self.cache.begin()
        while it != self.cache.end():
            cell = deref(it).first
            cells = deref(it).second

            size = cells.size()
            cell_array = clone(ARRAY_TEMPLATE, size, 0)
            memmove(&cell_array.data.as_ulonglongs[0], &cells[0], sizeof(uint64_t) * size)
            state[cell] = cell_array
            incr(it)
        return state

    def __setstate__(self, dict state):
        cdef:
            uint64_t cell
            vector[uint64_t] cells
        for cell, cells in state.items():
            self.cache[cell] = <vector[uint64_t]>cells

    def get_cell_ids(self, Location p):
        cdef:
            size_t size
            array cell_array
            vector[uint64_t] cells
            uint64_t cell = S2CellId.FromPoint(p.point).parent(S2_LEVEL).id()

        it = self.cache.find(cell)
        if it != self.cache.end():
            cells = deref(it).second
            size = cells.size()
            cell_array = clone(ARRAY_TEMPLATE, size, 0)
            memmove(&cell_array.data.as_ulonglongs[0], &cells[0], sizeof(uint64_t) * size)
            return cell_array

        cdef S2Cap cap = S2Cap.FromAxisHeight(p.point, AXIS_HEIGHT)
        self.coverer.GetCellIds(cap, &cells)
        self.cache[cell] = cells

        size = cells.size()
        cell_array = clone(ARRAY_TEMPLATE, size, 0)
        memmove(&cell_array.data.as_ulonglongs[0], &cells[0], sizeof(uint64_t) * size)
        return cell_array
