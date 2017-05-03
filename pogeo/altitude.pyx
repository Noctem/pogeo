# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.stdint cimport uint8_t, uint16_t, uint64_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from cython.operator cimport dereference as deref

from cyrandom.cyrandom cimport uniform

from ._urlencode cimport urlencode
from .cpython_ cimport Py_uhash_t
from .geo.s2 cimport S2Point
from .geo.s2cellid cimport S2CellId
from .geo.s2latlng cimport S2LatLng
from .libcpp_ cimport min
from .location cimport Location
from .polyline cimport encode_s2points
from .types cimport shape
from .utils cimport get_s2points

from pickle import dump, load, HIGHEST_PROTOCOL
from urllib.request import urlopen

try:
    from ujson import loads as json_loads
except ImportError:
    from json import loads as json_loads


cdef class AltitudeCache:
    def __cinit__(self, uint8_t level, double rand_min, double rand_max):
        self.changed = False
        self.level = level
        self.rand_min = rand_min
        self.rand_max = rand_max

    def __bool__(self):
        return True if self.cache.size() > 0 else False

    def __len__(self):
        return self.cache.size()

    def fetch_all(self, shape bounds, str key):
        cdef:
            vector[S2Point] points
            size_t i, size
            string poly
        self.bounds_hash = bounds.__hash__()
        points = get_s2points(bounds, self.level)
        size = points.size()
        for i in range(0, size, 300):
            poly = encode_s2points(points, i, min[size_t](i + 300, size))
            self.fetch_polyline(poly, key)

    def fetch_polyline(self, string poly, str key):
        cdef:
            dict response, result
            double lat, lon
            uint64_t cell_id
            str url = 'https://maps.googleapis.com/maps/api/elevation/json?locations=enc%3A{}&key={}'.format(urlencode(poly).decode('utf-8'), key)
        page = urlopen(url, timeout=10.0)
        response = json_loads(str(page.read(), encoding=page.headers.get_param("charset") or "utf-8"))
        for result in response['results']:
            lat = result['location']['lat']
            lon = result['location']['lng']
            cell_id = S2CellId.FromLatLng(S2LatLng.FromDegrees(lat, lon)).parent(self.level).id()
            self.cache[cell_id] = result['elevation']
        self.changed = True

    cpdef double get(self, Location loc):
        cdef uint64_t cell_id = S2CellId.FromPoint(loc.point).parent(self.level).id()
        cdef double alt

        it = self.cache.find(cell_id)
        if it != self.cache.end():
            alt = deref(it).second
            return uniform(alt - 2.5, alt + 2.5)

        return uniform(self.rand_min, self.rand_max)

    def random(self):
        return uniform(self.rand_min, self.rand_max)

    def set_alt(self, Location loc):
        loc.altitude = self.get(loc)

    def set_random(self, Location loc):
        loc.altitude = uniform(self.rand_min, self.rand_max)

    def pickle(self, str path):
        cdef dict state
        if self.changed:
            state = {
                'cache': self.cache,
                'level': self.level,
                'bounds_hash': self.bounds_hash
            }
            with open(path, 'wb') as f:
                dump(state, f, HIGHEST_PROTOCOL)
                self.changed = False

    def unpickle(self, str path, bounds):
        cdef dict state
        with open(path, 'rb') as f:
            state = load(f)
        if state['bounds_hash'] == bounds.__hash__() and state['level'] == self.level and state['cache']:
            self.cache = state['cache']
            return True
        return False
