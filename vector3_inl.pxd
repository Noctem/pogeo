cdef extern from "geometry/util/math/vector3-inl.h":
    cdef cppclass Vector3[T]:
        T& operator[](const int)
        T& x()
        T& y()
        T& z()
