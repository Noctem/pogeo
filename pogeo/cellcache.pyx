# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint64_t
from libc.string cimport memmove

from cython.operator cimport postincrement as incr, dereference as deref

from .array cimport array, clone
from .const cimport AXIS_HEIGHT
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .location cimport Location
from .types cimport vector_uint64
from .utils cimport ARRAY_TEMPLATE

DEF S2_LEVEL = 15


cdef class CellCache:
    def __cinit__(self):
        self.coverer.set_min_level(S2_LEVEL)
        self.coverer.set_max_level(S2_LEVEL)

    def __getstate__(self):
        cdef:
            uint64_t cell
            vector_uint64 cells
            array cell_array
            size_t size
            dict state = {}

        it = self.cache.begin()
        while it != self.cache.end():
            cell = deref(it).first
            cells = deref(it).second

            size = cells.size()
            cell_array = clone(ARRAY_TEMPLATE, size)
            memmove(&cell_array.data.as_ulonglongs[0], &cells[0], size * 8)
            state[cell] = cell_array
            incr(it)
        return state

    def __setstate__(self, dict state):
        cdef:
            uint64_t cell
            vector_uint64 cells
        for cell, cells in state.items():
            self.cache[cell] = <vector_uint64>cells

    def get_cell_ids(self, Location p):
        cdef:
            size_t size
            array cell_array
            vector_uint64 cells
            uint64_t cell = S2CellId.FromPoint(p.point).parent(S2_LEVEL).id()

        it = self.cache.find(cell)
        if it != self.cache.end():
            cells = deref(it).second
            size = cells.size()
            cell_array = clone(ARRAY_TEMPLATE, size)
            memmove(&cell_array.data.as_ulonglongs[0], &cells[0], size * 8)
            return cell_array

        cdef S2Cap cap = S2Cap.FromAxisHeight(p.point, AXIS_HEIGHT)
        self.coverer.GetCellIds(cap, &cells)
        self.cache[cell] = cells

        size = cells.size()
        cell_array = clone(ARRAY_TEMPLATE, size)
        memmove(&cell_array.data.as_ulonglongs[0], &cells[0], size * 8)
        return cell_array