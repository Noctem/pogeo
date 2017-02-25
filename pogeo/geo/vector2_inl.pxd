cdef extern from "vector2-inl.h" nogil:
    cdef cppclass Vector2[T]:
        T& operator[](const int)
        T& x()
        T& y()
