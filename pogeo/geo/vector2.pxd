from libc.stdint cimport uint8_t


cdef extern from "vector2.h" nogil:
    cdef cppclass Vector2[VType]:
        ctypedef Vector2[VType] Self
        ctypedef VType BaseType
        Vector2()
        Vector2(const VType x, const VType y)
        @staticmethod
        int Size()
        void Set(const VType x, const VType y)
        VType& operator[](const int b)
        VType x()
        VType y()

    ctypedef Vector2[uint8_t] Vector2_b
    ctypedef Vector2[int] Vector2_i
    ctypedef Vector2[float] Vector2_f
    ctypedef Vector2[double] Vector2_d
