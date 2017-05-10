from libcpp cimport bool, nullptr_t
from libcpp.map cimport map
from libcpp.string cimport string
from libcpp.vector cimport vector


cdef extern from "json11.hpp" namespace "json11" nogil:
    cdef enum JsonParse:
        STANDARD, COMMENTS

    cdef enum Type:
        NUL, NUMBER, BOOL, STRING, ARRAY, OBJECT

    cdef cppclass Json:
        ctypedef vector[Json] array
        ctypedef map[string, Json] object_

        Json()
        Json(nullptr_t)
        Json(double value)
        Json(int value)
        Json(bool value)
        Json(const string &value)
        Json(const char * value)
        Json(const array &values)
        Json(const object_ &values)

        Type type()

        bool is_null()
        bool is_number()
        bool is_bool()
        bool is_string()
        bool is_array()
        bool is_object()

        double number_value()
        int int_value()

        bool bool_value()
        string &string_value()
        array &array_items()
        object_ &object_items()

        Json &operator[](size_t i)
        Json &operator[](const string &key)
        string dump(int indent)

        void dump(string &out)
        string dump()

        @staticmethod
        Json parse(const string &in_, string &err)
