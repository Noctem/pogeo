from libcpp cimport bool

cdef extern from "<shared_mutex>" namespace "std" nogil:
    cdef cppclass shared_timed_mutex:
        shared_timed_mutex()
        # Exclusive ownership
        void lock()  # blocking
        bool try_lock()
        void unlock()

        # Shared ownership
        void lock_shared()  # blocking
        bool try_lock_shared()
        void unlock_shared()
