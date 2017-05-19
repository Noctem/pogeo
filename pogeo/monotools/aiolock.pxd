from libcpp cimport bool

cdef class AioLock:
    cdef:
        list _waiters
        object _loop
        bool locked

    cdef void release(self)
