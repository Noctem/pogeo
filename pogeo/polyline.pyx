# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=bytes, c_string_encoding=ascii

from libcpp.vector cimport vector

from cython.operator cimport dereference as deref, postincrement as incr

from ._json cimport Json
from ._mcpp cimport push_back_move
from .const cimport EARTH_RADIUS_METERS
from .geo.s1angle cimport S1Angle
from .geo.s2 cimport S2Point
from .geo.s2polyline cimport S2Polyline
from .location cimport Location
from .utils cimport coords_to_s2point


cdef class Polyline:
    @staticmethod
    cdef Polyline from_geojson(Json.array coords):
        cdef:
            vector[S2Point] points
            Polyline polyline = Polyline.__new__(Polyline)
            S2Point point

        it = coords.begin()
        while it != coords.end():
            # GeoJSON orders coordinates: lon, lat
            point = coords_to_s2point(deref(it)[1].number_value(), deref(it)[0].number_value())
            push_back_move(points, point)
            incr(it)

        polyline.line.Init(points)
        return polyline

    def __contains__(self, loc):
        return False

    def distance(self, Location loc):
        cdef:
            S2Point closest
            int next_vertex

        closest = self.line.Project(loc.point, &next_vertex)
        return S1Angle(closest, loc.point).radians() * EARTH_RADIUS_METERS

    def project(self, Location loc):
        cdef int next_vertex
        return Location.from_point(self.line.Project(loc.point, &next_vertex))

    @property
    def center(self):
        return Location.from_point(self.line.GetCentroid())

    @property
    def area(self):
        return 0
