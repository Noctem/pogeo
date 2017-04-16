from vector3_inl cimport Vector3


cdef extern from "geometry/util/math/vector3.h":
    ctypedef Vector3[double] Vector3_d
