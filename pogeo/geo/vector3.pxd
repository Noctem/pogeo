from libc.stdint cimport uint8_t
from libcpp cimport bool


cdef extern from "vector3.h" nogil:
    cdef cppclass Vector3[VType]:
        ctypedef Vector3[VType] Self
        ctypedef VType BaseType
        Vector3()
        Vector3(VType x, VType y, VType z)
        bool operator==(Self& vb)
        bool operator!=(Self& vb)
        @staticmethod
        int Size()
        void Set(VType x, VType y, VType z)
        Self& operator=(Self& vb)
        VType& operator[](const int)
        void x(VType &v)
        VType x()
        void y(VType &v)
        VType y()
        void z(VType &v)
        VType z()
        VType* Data()
        Self Normalize()
        void Clear()
        bool IsNaN()

    ctypedef Vector3[uint8_t] Vector3_b
    ctypedef Vector3[int] Vector3_i
    ctypedef Vector3[float] Vector3_f
    ctypedef Vector3[double] Vector3_d
