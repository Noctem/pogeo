# distutils: language = c++
# cython: language_level=3, cdivision=True

from libc.math cimport M_PI, pow

DEF CELL_RADIUS = 500

cdef double EARTH_RADIUS_KILOMETERS = 6371.0088
cdef double EARTH_RADIUS_METERS = 6371008.8
cdef double EARTH_RADIUS_MILES = EARTH_RADIUS_KILOMETERS * 0.621371
cdef double AXIS_HEIGHT = pow(CELL_RADIUS / EARTH_RADIUS_METERS, 2) / 2.0
cdef double RAD_TO_DEG = 180.0 / M_PI
cdef double DEG_TO_RAD = M_PI / 180.0
