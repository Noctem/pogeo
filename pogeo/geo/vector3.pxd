from .vector3_inl cimport Vector3


cdef extern from "vector3.h" nogil:
    ctypedef Vector3[double] Vector3_d
