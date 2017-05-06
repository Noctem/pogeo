# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=ascii

from libc.stdint cimport uint8_t, uint64_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from cython.operator cimport dereference as deref

from cyrandom.cyrandom cimport random, uniform

from ._urlencode cimport urlencode
from .cpython_ cimport Py_uhash_t
from .geo.s2 cimport S2Point
from .geo.s2cellid cimport S2CellId
from .geo.s2latlng cimport S2LatLng
from .libcpp_ cimport min
from .location cimport Location
from .polyline cimport encode_s2points
from .types cimport shape
from .utils cimport coords_to_s2point, get_s2points, time

from pickle import dump, load, HIGHEST_PROTOCOL
from time import sleep
from urllib.request import urlopen

try:
    from ujson import loads as json_loads
except ImportError:
    from json import loads as json_loads


DEF RETRY_TIMEOUT = 30.0
DEF COORDS_PER_REQUEST = 512


cdef class AltitudeCache:
    def __cinit__(self, uint8_t level, unicode key, double rand_min=390.0, double rand_max=490.0):
        self.changed = False
        self.level = level
        if key and not key.startswith("AIza"):
            raise ValueError("Invalid Google API key provided.")
        self.key = key
        self.rand_min = rand_min
        self.rand_max = rand_max

    def __bool__(self):
        return True if self.cache.size() > 0 else False

    def __len__(self):
        return self.cache.size()

    def fetch_all(self, shape bounds):
        cdef:
            vector[S2Point] points
            size_t i, size
            string poly
        self.bounds_hash = bounds.__hash__()
        points = get_s2points(bounds, self.level)
        size = points.size()
        for i in range(0, size, COORDS_PER_REQUEST):
            poly = urlencode(encode_s2points(points, i, min[size_t](i + COORDS_PER_REQUEST, size)))
            self.request(f'https://maps.googleapis.com/maps/api/elevation/json?locations=enc%3A{poly}&key={self.key}')

    def request(self, unicode url, float first_request_time=0.0, uint8_t retry_counter=0):
        cdef:
            dict response, result
            double lat, lon
            uint64_t cell_id
            float elapsed
            double delay_seconds

        if first_request_time == 0.0:
            first_request_time = time()
        else:
            elapsed = first_request_time - time()
            if elapsed > RETRY_TIMEOUT:
                raise ApiTimeout(f'{elapsed} elapsed since first request.')

            # 0.5 * (1.5 ^ i) is an increased sleep time of 1.5x per iteration,
            # starting at 0.5s when retry_counter=0. The first retry will occur
            # at 1, so subtract that first and jitter by 50%.
            delay_seconds = (0.5 * 1.5 ** (retry_counter - 1)) * (random() + 0.5)
            print(f'Sleeping for {delay_seconds:.1f} seconds before retrying altitude request.')
            sleep(delay_seconds)

        page = urlopen(url, timeout=10.0)
        if page.code == 500 or page.code == 503 or page.code == 504:
            self.request(url, first_request_time, retry_counter + 1)

        response = json_loads(page.read().decode(page.headers.get_param("charset") or "utf-8"))

        cdef str status = response['status']
        if status == 'OK':
            pass
        elif status == 'ZERO_RESULTS':
            return
        elif status == 'OVER_QUERY_LIMIT':
            self.request(url, first_request_time, retry_counter + 1)
        else:
            raise ApiError(response.get('error_message', status))

        for result in response['results']:
            lat = result['location']['lat']
            lon = result['location']['lng']
            cell_id = S2CellId.FromPoint(coords_to_s2point(lat, lon)).parent(self.level).id()
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

    def unpickle(self, unicode path, bounds):
        cdef dict state
        with open(path, 'rb') as f:
            state = load(f)
        if state['bounds_hash'] == bounds.__hash__() and state['level'] == self.level and state['cache']:
            self.cache = state['cache']
            return True
        return False


class ApiError(Exception):
    """Represents an exception returned by the remote API."""


class ApiTimeout(Exception):
    """The request timed out."""
