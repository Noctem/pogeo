# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8

from libc.stdint cimport uint16_t
from libcpp.pair cimport pair
from libcpp.string cimport string
from libcpp.vector cimport vector

from cython.operator cimport postincrement as incr, dereference as deref

from ._json cimport Json
from ._urlencode cimport urlencode

from urllib import request
cdef urlopen = request.urlopen
del request

def geocode(unicode query, double timeout=3.0):
    cdef:
        unicode url
        string err
        bytes page
        Json response
        Json.array coords
        vector[pair[double, double]] pairs
        dict place = {}

    query = urlencode(query.encode('utf-8'))
    url = f'https://nominatim.openstreetmap.org?format=json&polygon_geojson=1&q={query}'
    page = urlopen(url, timeout=timeout).read()

    response = Json.parse(page, err)[0]

    place['display_name'] = response[string(b'display_name')].string_value()
    place['shape_type'] = response[string(b'geojson')][string(b'type')].string_value()

    coords = response[string(b'geojson')][string(b'coordinates')][0].array_items()
    it = coords.begin()
    while it != coords.end():
        pairs.push_back(pair[double, double](deref(it)[1].number_value(), deref(it)[0].number_value()))
        incr(it)
    place['coords'] = pairs
    return place
