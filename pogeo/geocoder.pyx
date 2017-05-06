# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8

from libc.stdint cimport uint16_t
from libcpp.string cimport string

from ._urlencode cimport urlencode

from urllib.request import urlopen

try:
    from ujson import loads as json_loads
except ImportError:
    from json import loads as json_loads


def make_request(string url, double timeout):
    page = urlopen(url, timeout=timeout)
    return json_loads(page.read().decode(page.headers.get_param("charset") or "utf-8"))


def geocode(unicode query, double timeout=3.0):
    cdef:
        dict place
        list response
        string url = string(b'https://nominatim.openstreetmap.org?format=json&polygon_geojson=1&q=')
    url.append(urlencode(query))
    response = make_request(url, timeout)
    place = response[0]
    return place
