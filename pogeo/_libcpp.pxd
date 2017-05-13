from libcpp.pair cimport pair

cdef extern from "<algorithm>" namespace "std" nogil:
    T max[T](T a, T b)
    T min[T](T a, T b)
    pair make_pair[T1, T2](T1 t, T2 u)
