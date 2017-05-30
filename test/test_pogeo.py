#!/usr/bin/env python3

from array import array
from logging import getLogger
from pickle import loads as pickle_loads, dumps as pickle_dumps
from time import time
from unittest import main, skip, TestCase

from pogeo import CellCache, Location, Loop, Polygon, Rectangle
from pogeo.altitude import AltitudeCache
from pogeo.geocoder import geocode
from pogeo.polyline_encoder import encode_single, encode_multiple
from pogeo.utils import *


class TestAltitude(TestCase):
    def test_random(self):
        cache = AltitudeCache(13, 'AIzafake', 390.0, 490.0)
        self.assertTrue(390.0 <= cache.random() <= 490.0)

    def test_set_random(self):
        loc = Location(40.1, -110.1)
        cache = AltitudeCache(13, 'AIzafake', 1373.7, 1559.23)
        cache.set_random(loc)
        self.assertTrue(1373.7 <= loc[2] <= 1559.23)


class TestCellCache(TestCase):
    def test_get_cell_ids(self):
        cache = CellCache()
        cells = cache.get_cell_ids(Location(-75.56283, 153.23452))
        expected = array('Q', [12614130531357949952, 12614130645174583296, 12614130647322066944, 12614130649469550592, 12614130662354452480, 12614130664501936128, 12614130666649419776, 12614130668796903424, 12614130670944387072, 12614130673091870720, 12614130675239354368, 12614130677386838016, 12614130780466053120, 12614130782613536768])
        self.assertEqual(cells, expected)
        self.assertEqual(len(cache), 1)

    def test_cache(self):
        cache = CellCache()
        loc = Location(40.12345, -110.6789)
        cells = cache.get_cell_ids(loc)
        expected = array('Q', [9749833325740032000, 9749833327887515648, 9749833336477450240, 9749833338624933888, 9749833340772417536, 9749833342919901184, 9749833345067384832, 9749833347214868480, 9749833349362352128, 9749833351509835776, 9749833353657319424, 9749833355804803072, 9749833357952286720, 9749833360099770368, 9749833383722090496, 9749833385869574144, 9749833388017057792, 9749833390164541440, 9749833392312025088, 9749833437409181696, 9749833439556665344])
        self.assertEqual(cells, expected)
        self.assertEqual(len(cache), 1)
        cells = cache.get_cell_ids(loc)
        cells = cache.get_cell_ids(loc)
        self.assertEqual(cells, expected)
        self.assertEqual(len(cache), 1)
        cells = cache.get_cell_ids(Location(0.56283, -0.23452))
        self.assertEqual(len(cache), 2)


class TestGeocoder(TestCase):
    @skip('relies on network connection and external service')
    def test_geocode(self):
        log = getLogger('geocoder')
        place = geocode('Salt Lake Temple', log)
        self.assertAlmostEqual(place.area, 0.002, places=3)
        self.assertEqual(place.center, Location(40.77046869463424, -111.89191200565921))


class TestLocation(TestCase):
    def test_pickle(self):
        loc = Location(40.768721, -111.901673)
        pickled = pickle_dumps(loc)
        unpickled = pickle_loads(pickled)
        self.assertEqual(loc.coords, unpickled.coords)

    def test_jitter(self):
        lat = 40.777452
        lon = -111.887663
        loc = Location(lat, lon)
        loc.jitter(0.03, 0.07)
        self.assertNotEqual(loc[0], lat)
        self.assertNotEqual(loc[1], lon)
        self.assertTrue(lat - 0.03 <= loc[0] <= lat + 0.03)
        self.assertTrue(lon - 0.07 <= loc[1] <= lon + 0.07)

    def test_time(self):
        loc = Location(40.768721, -111.901673)
        t = time()
        loc.update_time()
        self.assertTrue(t - 1 <= loc.time <= t + 1)


CCW_TRIANGLE = ((40.7694, -111.8938), (40.7694, -111.8884), (40.7713, -111.8911))
CW_TRIANGLE = ((40.7694, -111.8938), (40.7713, -111.8911), (40.7694, -111.8884))
TRAPEZOID = ((40.7589, -111.8522), (40.7589, -111.8283), (40.7686, -111.8323), (40.7686, -111.8478))


class TestLoop(TestCase):
    def test_ccw_area(self):
        loop = Loop(CCW_TRIANGLE)
        self.assertAlmostEqual(loop.area, 0.04804, places=5)

    def test_cw_area(self):
        loop = Loop(CW_TRIANGLE)
        self.assertAlmostEqual(loop.area, 0.04804, places=5)

    def test_contains_location(self):
        loop = Loop(CCW_TRIANGLE)
        self.assertTrue(Location(40.7704, -111.8910) in loop)
        self.assertFalse(Location(40.2497, -111.6492) in loop)

    def test_contains_cell(self):
        loop = Loop(TRAPEZOID)
        self.assertTrue(loop.contains_cellid(9750961227101634560))
        self.assertTrue(loop.contains_token('87525f92c'))
        self.assertFalse(loop.contains_cellid(9749607897939050496))
        self.assertFalse(loop.contains_token('874d90ba4'))

    def test_json(self):
        loop = Loop(TRAPEZOID)
        expected = b'{"areas": [[[40.75890, -111.85220], [40.75890, -111.82830], [40.76860, -111.83230], [40.76860, -111.84780], [40.75890, -111.85220]]], "holes": []}'
        self.assertEqual(loop.json, expected)


class TestPolygon(TestCase):
    def test_area(self):
        polygon = Polygon((CCW_TRIANGLE, TRAPEZOID))
        self.assertAlmostEqual(polygon.area, 1.83753, places=5)

    def test_hole(self):
        hole = ((40.76170, -111.83719), (40.76304, -111.83840), (40.76308, -111.83970), (40.76216, -111.84007), (40.76083, -111.83894)),
        polygon = Polygon((CCW_TRIANGLE, TRAPEZOID), hole)
        self.assertAlmostEqual(polygon.area, 1.80089, places=5)

    def test_contains_location(self):
        polygon = Polygon((TRAPEZOID, CW_TRIANGLE))
        self.assertTrue(Location(40.7704, -111.8910) in polygon)
        self.assertFalse(Location(40.2497, -111.6492) in polygon)

    def test_contains_cell(self):
        polygon = Polygon((TRAPEZOID, CCW_TRIANGLE))
        self.assertTrue(polygon.contains_cellid(9750961227101634560))
        self.assertTrue(polygon.contains_token('87525f92c'))
        self.assertFalse(polygon.contains_cellid(9749607897939050496))
        self.assertFalse(polygon.contains_token('874d90ba4'))

    def test_json(self):
        hole = ((40.76170, -111.83719), (40.76304, -111.83840), (40.76308, -111.83970), (40.76216, -111.84007), (40.76083, -111.83894)),
        polygon = Polygon((TRAPEZOID, CCW_TRIANGLE), hole)
        expected = b'{"areas": [[[40.75890, -111.82830], [40.76860, -111.83230], [40.76860, -111.84780], [40.75890, -111.85220], [40.75890, -111.82830]], [[40.76940, -111.88840], [40.77130, -111.89110], [40.76940, -111.89380], [40.76940, -111.88840]]], "holes": [[[40.76170, -111.83719], [40.76304, -111.83840], [40.76308, -111.83970], [40.76216, -111.84007], [40.76083, -111.83894], [40.76170, -111.83719]]]}'
        self.assertEqual(polygon.json, expected)


class TestPolylineEncoder(TestCase):
    def test_single(self):
        self.assertEqual(encode_single(Location(40.761731, -111.901111)), 'ygxwF|t~iT')

    def test_multiple(self):
        points = (Location(40.2634, -111.6406), Location(40.2484, -111.6513), Location(40.2362, -111.6364))
        self.assertEqual(encode_multiple(points), 'g}vtFvxkhTv|AzaAfkAc|A')


class TestRectangle(TestCase):
    def test_area(self):
        rectangle = Rectangle((40.2557, -111.6561), (40.2459, -111.643241))
        self.assertAlmostEqual(rectangle.area, 1.1892, places=5)

    def test_contains_location(self):
        rectangle = Rectangle((40.2557, -111.6561), (40.2459, -111.643241))
        self.assertTrue(Location(40.2497, -111.6492) in rectangle)
        self.assertFalse(Location(40.7704, -111.8910) in rectangle)

    def test_contains_cell(self):
        rectangle = Rectangle((40.2557, -111.6561), (40.2459, -111.643241))
        self.assertTrue(rectangle.contains_cellid(9749607897939050496))
        self.assertTrue(rectangle.contains_token('874d90ba4'))
        self.assertFalse(rectangle.contains_cellid(9750961227101634560))
        self.assertFalse(rectangle.contains_token('87525f92c'))

    def test_json(self):
        rectangle = Rectangle((40.2557, -111.6561), (40.2459, -111.643241))
        expected = b'{"areas": [[[40.25570, -111.65610], [40.24590, -111.65610], [40.24590, -111.64324], [40.25570, -111.64324], [40.25570, -111.65610]]], "holes": []}'
        self.assertEqual(rectangle.json, expected)


class TestUtils(TestCase):
    def test_distance_to_latlon(self):
        lat, lon = distance_to_latlon(Location(40.2497, -111.6492), 70.0)
        self.assertAlmostEqual(lat, 0.00063, places=5)
        self.assertAlmostEqual(lon, 0.00082, places=5)

    def test_diagonal_distance(self):
        lat, lon = diagonal_distance(Location(40.2497, -111.6492), 500.0)
        self.assertAlmostEqual(lat, 0.00383, places=5)
        self.assertAlmostEqual(lon, 0.00309, places=5)

    def test_get_cell_ids(self):
        cells = get_cell_ids(Location(40.12345, -110.6789))
        expected = array('Q', [9749833325740032000, 9749833327887515648, 9749833336477450240, 9749833338624933888, 9749833340772417536, 9749833342919901184, 9749833345067384832, 9749833347214868480, 9749833349362352128, 9749833351509835776, 9749833353657319424, 9749833355804803072, 9749833357952286720, 9749833360099770368, 9749833383722090496, 9749833385869574144, 9749833388017057792, 9749833390164541440, 9749833392312025088, 9749833437409181696, 9749833439556665344])
        self.assertEqual(cells, expected)

    def test_closest_levels(self):
        self.assertEqual(closest_level_edge(140.0), 16)
        self.assertEqual(closest_level_width(70.0), 17)
        self.assertEqual(closest_level_area(600.0), 19)

    def test_level_sizes(self):
        self.assertAlmostEqual(level_width(15), 278.91, places=2)
        self.assertAlmostEqual(level_edge(12), 2269.69, places=2)
        self.assertAlmostEqual(level_area(14), 316690.58, places=2)

    def test_cellid_to_location(self):
        loc = cellid_to_location(9299287131783)
        lat, lon = cellid_to_coords(9299287131783)
        self.assertAlmostEqual(loc[0], 40.72179, places=5)
        self.assertAlmostEqual(loc[1], -111.93571, places=5)
        self.assertAlmostEqual(lat, 40.72179, places=5)
        self.assertAlmostEqual(lon, -111.93571, places=5)

    def test_token_to_location(self):
        loc = token_to_location('8752f411ca9')
        lat, lon = token_to_coords('8752f411ca9')
        self.assertAlmostEqual(loc[0], 40.78931, places=5)
        self.assertAlmostEqual(loc[1], -111.93888, places=5)
        self.assertAlmostEqual(lat, 40.78931, places=5)
        self.assertAlmostEqual(lon, -111.93888, places=5)

    def test_location_to_cellid(self):
        loc = Location(40.2637, -111.639794)
        raw = location_to_cellid(loc, 20, False)
        stripped = location_to_cellid(loc, 20, True)
        self.assertEqual(raw, 9749608109427392512)
        self.assertEqual(stripped, 9297950848987)

    def test_location_to_token(self):
        loc = Location(40.2637, -111.639794)
        token = location_to_token(loc, 20)
        self.assertEqual(token, '874d90eb7db')

    def test_get_bearing(self):
        loc1 = Location(40.239416, -111.643654)
        loc2 = Location(40.248302, -111.620660)
        self.assertAlmostEqual(get_bearing(loc1, loc2), 63.14, places=2)

    def test_get_distance_miles(self):
        miles = get_distance_unit(Location(-37.12345, 73.6789), Location(-37.54321, 73.9876), 1)
        self.assertAlmostEqual(miles, 33.5971, places=4)

    def test_get_distance_kilometers(self):
        kilometers = get_distance_unit(Location(.5, .5), Location(-.5, -.5), 2)
        self.assertAlmostEqual(kilometers, 157.2526, places=4)

    def test_get_distance_meters(self):
        meters = get_distance_unit(Location(88, 188), Location(89, 189), 3)
        self.assertAlmostEqual(meters, 111228.94, places=2)

    def test_get_distance(self):
        meters1 = get_distance(Location(12.3456, -65.4321), Location(12.7373, -65.1212))
        meters2 = get_distance_unit(Location(12.3456, -65.4321), Location(12.7373, -65.1212), 3)
        self.assertEqual(meters1, meters2)
        self.assertAlmostEqual(meters1, 55098.21, places=2)


if __name__ == '__main__':
    main()
