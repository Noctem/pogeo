cdef extern from "Python.h":
    ctypedef long long _PyTime_t
    _PyTime_t _PyTime_GetSystemClock()
    Py_hash_t _Py_HashDouble(double v)
    ctypedef size_t Py_uhash_t
    ctypedef Py_ssize_t Py_hash_t
