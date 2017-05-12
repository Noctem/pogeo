from libcpp cimport bool

cdef extern from "<mutex>" namespace "std" nogil:
    cdef cppclass mutex:
        mutex()
        void lock()
        bool try_lock()
        void unlock()
