cdef extern from "Python.h":
    ctypedef long long _PyTime_t
    char* _Py_dg_dtoa(double d, int mode, int ndigits, int *decpt, int *sign, char **rve)
    double _Py_dg_strtod(const char *str, char **ptr)
    void _Py_dg_freedtoa(char *s)
    int PyOS_snprintf(char *str, size_t size, const char  *format, char*, char*, int)
    _PyTime_t _PyTime_GetSystemClock()
    Py_hash_t _Py_HashDouble(double v)
    ctypedef size_t Py_uhash_t
    ctypedef Py_ssize_t Py_hash_t
