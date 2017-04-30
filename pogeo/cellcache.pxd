from .types cimport cell_map
from .geo.s2regioncoverer cimport S2RegionCoverer


cdef class CellCache:
    cdef cell_map cache
    cdef S2RegionCoverer coverer
