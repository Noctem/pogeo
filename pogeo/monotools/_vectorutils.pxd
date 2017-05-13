from libcpp.string cimport string

from .._json cimport Json


cdef extern from "vectorutils.h" nogil:
    void dump_after_id(const Json.array &arr, int index, string &output)
    string dump_after_id(const Json.array &arr, int index)
    void remove_expired(Json.array &arr, int now)
