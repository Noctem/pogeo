#include <Python.h>

#include "s2.h"
#include "s2cap.h"
#include "s2cellid.h"
#include "s2latlng.h"
#include "s2regioncoverer.h"

const double kEarthCircumferenceMeters = 6371008.8 * M_PI * 2;

// Generates a list of cells at the target s2 cell levels which cover
// a cap of radius 'radius_meters' with center at lat & lng.
static PyObject *GetCellIDs(PyObject *self, PyObject *args) {
  double lat, lon;
  unsigned short int radius;
  radius = 500;
  if (!PyArg_ParseTuple(args, "dd|H", &lat, &lon, &radius))
    return NULL;
  const S2Cap region = S2Cap::FromAxisAngle(
      S2LatLng::FromDegrees(lat, lon).ToPoint(),
      S1Angle::Degrees(360 * radius / kEarthCircumferenceMeters));
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
