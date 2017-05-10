cdef extern from "bitscan.h" nogil:
    inline unsigned long leadingZeros(unsigned long long x)
