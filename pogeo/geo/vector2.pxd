from libc.stdint cimport uint8_t

from .vector2_inl cimport Vector2


cdef extern from "vector2.h" nogil:
    ctypedef Vector2[uint8_t] Vector2_b
    ctypedef Vector2[int] Vector2_i
    ctypedef Vector2[float] Vector2_f
    ctypedef Vector2[double] Vector2_d
