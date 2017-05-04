cdef extern from "<algorithm>" namespace "std" nogil:
    T max[T](T a, T b)
    T min[T](T a, T b)
    Iter remove_if[Iter, UnaryPredicate](Iter first, Iter last, UnaryPredicate p)
