from libcpp.string cimport string

cdef extern from "_urlencode.h" nogil:
    string urlencode(const string& src)
