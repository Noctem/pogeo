from libcpp.vector cimport vector

from s2 cimport S2Point
from s2region cimport S2Region
from s2cellid cimport S2CellId


cdef extern from "geometry/s2/s2regioncoverer.h":
    cdef cppclass S2RegionCoverer:
        S2RegionCoverer()
        void set_min_level(int min_level)
        void set_max_level(int max_level)
        int min_level()
        int max_level()
        void set_level_mod(int level_mod)
        int level_mod()
        void set_max_cells(int max_cells)
        int max_cells()
        void GetCoveringInternal(S2Region region)
        void GetCovering(S2Region region, vector[S2CellId]* covering)
        void GetCellIds(S2Region region, vector[unsigned long long]* covering)
        @staticmethod
        void GetSimpleCovering(S2Region region, S2Point start, int level, vector[S2CellId]* output)
        @staticmethod
        void GetSimpleCoveringId(S2Region region, S2Point start, unsigned char level, vector[unsigned long long]* output)
