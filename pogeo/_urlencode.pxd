from libcpp.string cimport string

cdef extern from "urlencode.h" nogil:
    string urlencode(const string& src)
