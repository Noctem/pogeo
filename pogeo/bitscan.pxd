cdef extern from "bitscan.h" nogil:
    unsigned int bitScanReverse(unsigned long long x)
