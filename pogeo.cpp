#include <Python.h>

#include "s2.h"
#include "s2cap.h"
#include "s2cellid.h"
#include "s2latlng.h"
#include "s2regioncoverer.h"

const double kEarthRadiusKilometers = 6371.0088;
const double kEarthRadiusMeters = kEarthRadiusKilometers * 1000;
const double kEarthRadiusMiles = kEarthRadiusKilometers * 0.621371;
const double radToDeg = 180.0 / M_PI;
const double degToRad = M_PI / 180.0;

double RadiansToDistance(double radians, char *unit) {
  const double *radius;

  switch(*unit) {
    case 1 :
      radius = &kEarthRadiusMiles;
      break;
    case 2 :
      radius = &kEarthRadiusKilometers;
      break;
    case 3 :
      radius = &kEarthRadiusMeters;
      break;
  }

  return (radians * *radius);
}

// Returns the bearing between two locations.
static PyObject *GetBearing(PyObject *self, PyObject *args) {
  double lat1, lon1, lat2, lon2;

  if (!PyArg_ParseTuple(args, "(dd)(dd):GetBearing", &lat1, &lon1, &lat2, &lon2))
    return NULL;

  lat1 *= degToRad;
  lat2 *= degToRad;

  double lonDiff = (lon2 - lon1) * degToRad;
  double x = sin(lonDiff) * cos(lat2);
  double y = cos(lat1) * sin(lat2) - (sin(lat1) * cos(lat2) * cos(lonDiff));
  double initial_bearing = atan2(x, y);
  initial_bearing = fmod(initial_bearing * radToDeg + 360, 360);

  PyObject *bearing;
  bearing = PyFloat_FromDouble(initial_bearing);

  return bearing;
}

// Returns the distance between two locations.
static PyObject *GetDistance(PyObject *self, PyObject *args) {
  double lat1, lon1, lat2, lon2;
  char unit = 3;

  if (!PyArg_ParseTuple(args, "(dd)(dd)|b:GetDistance", &lat1, &lon1, &lat2, &lon2, &unit))
    return NULL;

  S2LatLng latlon1 = S2LatLng::FromDegrees(lat1, lon1);
  S2LatLng latlon2 = S2LatLng::FromDegrees(lat2, lon2);

  PyObject *distance;
  distance = PyFloat_FromDouble(RadiansToDistance(latlon1.GetDistance(latlon2).radians(), &unit));

  return distance;
}

// Generates a list of cells at the target s2 cell levels which cover
// a cap of radius 'radius_meters' with center at lat & lng.
static PyObject *GetCellIDs(PyObject *self, PyObject *args) {
  double lat, lon;
  unsigned short int radius = 500;
  if (!PyArg_ParseTuple(args, "dd|H:GetCellIDs", &lat, &lon, &radius))
    return NULL;
  const S2Cap region = S2Cap::FromAxisAngle(
      S2LatLng::FromDegrees(lat, lon).ToPoint(),
      S1Angle::Degrees(360 * radius / (kEarthRadiusMeters * M_PI * 2)));
  S2RegionCoverer coverer;
  coverer.set_min_level(15);
  coverer.set_max_level(15);

  vector<S2CellId> covering;
  coverer.GetCovering(region, &covering);
  PyObject *cells, *cell;
  cells = PyTuple_New(covering.size());
  for (size_t i = 0; i < covering.size(); ++i) {
    cell = PyLong_FromUnsignedLongLong(covering[i].id());
    PyTuple_SetItem(cells, i, cell);
  }
  return cells;
}

/* List of functions defined in the module */
static PyMethodDef PogeoMethods[] = {
    {"get_cell_ids", GetCellIDs, METH_VARARGS,
     "Get the cell IDs for the given coordinates."},
    {"get_distance", GetDistance, METH_VARARGS,
     "Get the distance between two points."},
    {"get_bearing", GetBearing, METH_VARARGS,
     "Calculates the bearing between two points."},
    {NULL, NULL, 0, NULL} /* sentinel */
};

static struct PyModuleDef pogeomodule = {
    PyModuleDef_HEAD_INIT, "pogeo", /* name of module */
    NULL,                           /* module documentation, may be NULL */
    -1, /* size of per-interpreter state of the module,
           or -1 if the module keeps state in global variables. */
    PogeoMethods
};

PyMODINIT_FUNC PyInit_pogeo(void) { return PyModule_Create(&pogeomodule); }
