cdef extern from "vector3-inl.h" nogil:
    cdef cppclass Vector3[T]:
        T& operator[](const int)
        T& x()
        T& y()
        T& z()
