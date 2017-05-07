from libcpp.string cimport string

cdef extern from "gzip.h" namespace "gzip" nogil:
    string compress(const string& data, string compressedData, int level)
