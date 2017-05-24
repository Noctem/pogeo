# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8

from libcpp.string cimport string
from libcpp.vector cimport vector

from cython.operator cimport dereference as deref, postincrement as incr

from ._json cimport Json
from ._urlencode cimport urlencode
from .location cimport Location
from .loop cimport Loop
from .polygon cimport Polygon
from .polyline cimport Polyline

from urllib import request
cdef urlopen = request.urlopen
del request


def geocode(unicode query, object log, double timeout=3.0):
    cdef:
        unicode url, display_name
        string shape_type, err
        bytes page
        Json response
        Json.array coords

    url = f'https://nominatim.openstreetmap.org?format=json&polygon_geojson=1&q={urlencode(query.encode("utf-8"))}'
    page = urlopen(url, timeout=timeout).read()

    response = Json.parse(page, err)[0]

    display_name = response[string(b'display_name')].string_value()
    shape_type = response[string(b'geojson')][string(b'type')].string_value()

    log.warning(f'Nominatim returned a {shape_type} of {display_name} for {query}')

    coords = response[string(b'geojson')][string(b'coordinates')].array_items()

    if shape_type == string(b'Point'):
        return Location(coords[1].number_value(), coords[0].number_value())
    elif shape_type == string(b'Polygon'):
        if coords.size() == 1:
            # no holes provided, construct a Loop
            return Loop.from_geojson(coords[0].array_items())
        else:
            # holes provided, construct a Polygon
            return Polygon.from_geojson(coords)
    elif shape_type == string(b'MultiPolygon'):
        return Polygon.from_geojson(coords)
    elif shape_type == string(b'LineString'):
        return Polyline.from_geojson(coords)
    else:
        raise NotImplementedError(f'{shape_type} is not currently supported')
