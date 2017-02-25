from libc.stdint cimport uint8_t

from .vector3_inl cimport Vector3


cdef extern from "vector3.h" nogil:
    ctypedef Vector3[uint8_t] Vector3_b
    ctypedef Vector3[int] Vector3_i
    ctypedef Vector3[float] Vector3_f
    ctypedef Vector3[double] Vector3_d
