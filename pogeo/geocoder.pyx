# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint16_t
from libcpp.string cimport string

from ._urlencode cimport urlencode

from urllib.request import urlopen

try:
    from ujson import loads as json_loads
except ImportError:
    from json import loads as json_loads


cdef string quote(str s):
    return urlencode(s.encode('utf-8'))


def make_request(string url, double timeout):
    page = urlopen(url.decode('utf-8'), timeout=timeout)
    return json_loads(str(page.read(), encoding=page.headers.get_param("charset") or "utf-8"))


def geocode(str query, double timeout=3.0):
    cdef:
        dict place
        list response
        string url = string(<char *>'https://nominatim.openstreetmap.org?format=json&polygon_geojson=1&q=')
    url.append(quote(query))
    response = make_request(url, timeout)
    place = response[0]
    return place

