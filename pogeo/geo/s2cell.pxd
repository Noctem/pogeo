from .s2cellid cimport S2CellId
from .s2region cimport S2Region

cdef extern from "s2cell.h" nogil:
    cdef cppclass S2Cell(S2Region):
        S2Cell(S2CellId id)
