from libc.stdint cimport int32_t, int64_t


cdef extern from "mathutil.h" nogil:
    cdef cppclass MathUtil:
        @staticmethod
        unsigned int GCD(unsigned int x, unsigned int y)
        @staticmethod
        unsigned int LeastCommonMultiple(unsigned int a, unsigned int b)
        @staticmethod
        int32_t FastIntRound(double x)
        @staticmethod
        int64_t FastInt64Round(double x)
        @staticmethod
        T Max[T](const T x, const T y)
        @staticmethod
        T Min[T](const T x, const T y)
        @staticmethod
        T Abs[T](const T x)
