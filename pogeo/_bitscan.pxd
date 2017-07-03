cdef extern from "bitscan.h" nogil:
    unsigned long leadingZeros(unsigned long long x)
    unsigned long trailingZeros(unsigned long long x)
