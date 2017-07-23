# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=bytes, c_string_encoding=ascii, auto_pickle=False

from libc.math cimport log2, pow
from libc.stdint cimport uint64_t
from libcpp.string cimport string
from libcpp.vector cimport vector

from cython.operator cimport dereference as deref, postincrement as incr

from ._cpython cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from ._json cimport Json
from ._mcpp cimport emplace_move, push_back_move
from .geo.s2 cimport S2Point
from .geo.s2cellid cimport S2CellId
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
from .geo.s2regioncoverer cimport S2RegionCoverer
from .location cimport Location
from .utils cimport coords_to_s2point, s2point_to_lat, s2point_to_lon


include "const.pxi"


cdef class Loop:
    def __init__(self, tuple coords):
        cdef:
            vector[S2Point] points
            S2Point point

        for p in coords:
            point = coords_to_s2point(p[0], p[1])
            push_back_move(points, point)

        self.shape.Init(points)
        self._initialize()

    def __bool__(self):
        return True

    def __hash__(self):
        cdef Py_uhash_t mult = 1000003
        cdef Py_uhash_t x = 0x345678
        cdef Py_hash_t y

        cdef double[5] inputs = [self.south, self.east, self.north, self.west, <double>self.shape.num_vertices()]
        cdef double i
        for i in inputs:
            y = _Py_HashDouble(i)
            x = (x ^ y) * mult
            mult += <Py_hash_t>(82520 + 10)
        return x + 97531

    def __contains__(self, Location loc):
        return self.shape.Contains(loc.point)

    def __getnewargs__(self):
        return None,

    def __getstate__(self):
        cdef:
            S2Point s2p
            list vertices = []
            int i, length = self.shape.num_vertices()

        for i in range(length):
            s2p = self.shape.vertex(i)
            vertices.append((s2p[0], s2p[1], s2p[2]))
        return vertices

    def __setstate__(self, list state):
        cdef:
            tuple point
            vector[S2Point] points
            size_t i, length = len(state)

        for i in range(length):
            point = state[i]
            emplace_move(points, <double>point[0], <double>point[1], <double>point[2])

        self.shape.Init(points)
        self._initialize()

    cdef void _initialize(self):
        # if loop covers more than half of the Earth's surface it was probably
        # erroneously constructed clockwise
        if self.shape.GetArea() > (PI * 2):
            self.shape.Invert()

        cdef S2LatLngRect rect = self.shape.GetRectBound()
        self.south = rect.lat_lo().degrees()
        self.east = rect.lng_hi().degrees()
        self.north = rect.lat_hi().degrees()
        self.west = rect.lng_lo().degrees()

    def get_points(self, int level):
        cdef S2RegionCoverer coverer
        coverer.set_min_level(level)
        coverer.set_max_level(level)
        cdef vector[S2Point] points
        coverer.GetPoints(self.shape, &points)
        cdef size_t i, size = points.size()
        for i in range(size):
            yield Location.from_point(points.back())
            points.pop_back()

    def contains_cellid(self, uint64_t cellid):
        return self.shape.Contains(S2CellId(cellid << (63 - <int>log2(cellid))).ToPointRaw())

    def contains_token(self, unicode t):
        return self.shape.Contains(S2CellId.FromToken(t).ToPointRaw())

    def distance(self, Location loc):
        return self.shape.GetDistance(loc.point).radians() * EARTH_RADIUS_METERS

    def project(self, Location loc):
        return Location.from_point(self.shape.Project(loc.point))

    @staticmethod
    cdef Loop from_geojson(Json.array coords):
        cdef:
            vector[S2Point] points
            Loop loop = Loop.__new__(Loop, None)
            S2Point point

        it = coords.begin()
        while it != coords.end():
            # GeoJSON orders coordinates: lon, lat
            point = coords_to_s2point(deref(it)[1].number_value(), deref(it)[0].number_value())
            push_back_move(points, point)
            incr(it)

        loop.shape.Init(points)
        loop._initialize()
        return loop

    @property
    def json(self):
        cdef:
            Json.object_ jobject
            Json.array areas, area, coords
            S2Point vertex
            int i, vertices = self.shape.num_vertices()

        jobject[string(b'holes')] = Json(areas)

        coords = Json.array(<size_t>2)

        for i in range(vertices):
            vertex = self.shape.vertex(i)
            coords[0] = Json(s2point_to_lat(vertex))
            coords[1] = Json(s2point_to_lon(vertex))
            area.push_back(Json(coords))

        area.push_back(area.front())

        areas.push_back(Json(area))
        jobject[string(b'areas')] = Json(areas)
        return Json(jobject).dump()

    @property
    def center(self):
        return Location.from_point(self.shape.GetCentroid().Normalize())

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.shape.GetArea() * pow(EARTH_RADIUS_KILOMETERS, 2)
