# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint64_t
from libc.string cimport memcpy
from libcpp.vector cimport vector
from libcpp.unordered_map cimport unordered_map

from cython.operator cimport dereference as deref

from .array cimport array, clone
from .const cimport AXIS_HEIGHT
from .geo.s2 cimport S2Point
from .geo.s2cap cimport S2Cap
from .geo.s2cellid cimport S2CellId
from .location cimport Location
from .types cimport vector_uint64

DEF S2_LEVEL = 15

cdef array ARRAY_TEMPLATE = array('Q', [])


cdef class CellCache:
    def __cinit__(self):
        self.coverer.set_min_level(S2_LEVEL)
        self.coverer.set_max_level(S2_LEVEL)

    def get_cell_ids(self, Location p):
        cdef size_t size
        cdef array cell_array
        cdef S2Point point = p.point
        cdef uint64_t cell = S2CellId.FromPoint(point).parent(S2_LEVEL).id()

        it = self.cache.find(cell)
        if it != self.cache.end():
            size = deref(it).second.size()
            cell_array = clone(ARRAY_TEMPLATE, size)
            memcpy(&cell_array.data.as_ulonglongs[0], &deref(it).second, size * 8)
            return cell_array

        cdef S2Cap cap = S2Cap.FromAxisHeight(point, AXIS_HEIGHT)

        cdef vector_uint64 cells
        self.coverer.GetCellIds(cap, &cells)

        size = cells.size()
        cell_array = clone(ARRAY_TEMPLATE, size)
        memcpy(&cell_array.data.as_ulonglongs[0], &cells[0], size * 8)
        self.cache[cell] = cells

        return cell_array
