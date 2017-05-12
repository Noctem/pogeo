from libc.stdint cimport int64_t


cdef extern from "Python.h":
    ctypedef int64_t _PyTime_t
    _PyTime_t _PyTime_GetSystemClock()
    _PyTime_t _PyTime_GetMonotonicClock()
    Py_hash_t _Py_HashDouble(double v)
    ctypedef size_t Py_uhash_t
    ctypedef Py_ssize_t Py_hash_t
