from libcpp cimport bool
from libcpp.vector cimport vector

from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .const cimport EARTH_RADIUS_KILOMETERS
from .cpylib cimport _Py_HashDouble, Py_hash_t, Py_uhash_t
from .geo.s2 cimport S2, S2Point
from .geo.s2latlng cimport S2LatLng
from .geo.s2latlngrect cimport S2LatLngRect
from .geo.s2loop cimport S2Loop
from .geo.s2polygonbuilder cimport S2PolygonBuilder
from .location cimport Location
from .utils cimport coords_to_s2point


cdef class Polygon:
    def __cinit__(self, tuple boundaries):
        cdef:
            tuple points, coords
            double lat, lon
            vector[S2Point] pv
            S2Point a, b, c
            S2PolygonBuilder builder
            S2PolygonBuilder.EdgeList edge_list
            bool ccw

        for points in boundaries:
            self.create_loop(points, &builder)

        builder.AssemblePolygon(&self.polygon, &edge_list)
        cdef S2LatLngRect rect = self.polygon.GetRectBound()
        self.south = rect.lat_lo().degrees()
        self.east = rect.lng_hi().degrees()
        self.north = rect.lat_hi().degrees()
        self.west = rect.lng_lo().degrees()

    cdef void create_loop(self, tuple points, S2PolygonBuilder* builder):
        cdef vector[S2Point] v
        cdef S2Loop loop
        for coords in points:
            lat, lon = coords
            v.push_back(coords_to_s2point(lat, lon))
        loop.Init(v)
        builder.AddLoop(&loop)

    def __contains__(self, Location loc):
        cdef S2Point p = loc.point
        return self.polygon.Contains(p)

    def __hash__(self):
        cdef Py_uhash_t mult = 1000003
        cdef Py_uhash_t x = 0x345678
        cdef Py_hash_t y

        cdef double[5] inputs = [self.south, self.east, self.north, self.west, <double>self.polygon.num_vertices()]
        cdef double i
        for i in inputs:
            y = _Py_HashDouble(i)
            x = (x ^ y) * mult
            mult += <Py_hash_t>(82520 + 10)
        return x + 97531

    @property
    def bounds(self):
        return self.south, self.east, self.north, self.west

    @property
    def area(self):
        """Returns the square kilometers for configured area"""
        return self.polygon.GetArea() * pow(EARTH_RADIUS_KILOMETERS, 2)
