# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=unicode, c_string_encoding=utf-8, boundscheck=False

from libc.stdint cimport int16_t, uint64_t
from libcpp.set cimport set
from libcpp.string cimport string

from cython.operator cimport preincrement as incr, dereference as deref

from ._sqlalchemy cimport get_results
from .geo.s2 cimport S2Point
from .libcpp_ cimport remove_if
from .json cimport Json
from .utils cimport int_time, cellid_to_s2point, s2point_to_lat, s2point_to_lon

DEF INDEX = 0
DEF POKEMON_ID = 1
DEF SPAWN_ID = 2
DEF EXPIRATION = 3


cdef class WebCache:
    def __cinit__(self, set[int16_t] trash, dict names, tuple filter_ids, tuple columns, object session_maker):
        self.trash = trash
        self.names = {k: v.encode('utf-8') for k,v in names.items()}
        self.columns = columns
        self.last_update = 0
        self.session_maker = session_maker
        self.filter_ids = filter_ids

    cdef void update_cache(self):
        cdef:
            Json.object_ jobject
            S2Point point
            int id_
            int16_t pokemon_id
            list results
            tuple pokemon
            object query, session
            Py_ssize_t i, length
            string i_id = string(b'id')
            string i_lat = string(b'lat')
            string i_lon = string(b'lon')
            string i_trash = string(b'trash')
            string i_name = string(b'name')
            string i_expires = string(b'expires_at')

        self.last_update = int_time()

        session = self.session_maker(autoflush=False)
        try:
            query = session.query(*self.columns).filter(self.columns[EXPIRATION] > int_time(), self.columns[INDEX] > self.last_id)
            if self.filter_ids:
                query = query.filter(~self.query[POKEMON_ID].in_(self.filter_ids))
            results = get_results(query)
        except Exception:
            session.rollback()
            session.close()
            raise
        else:
            del query, session

        length = len(results)

        for i in range(length):
            pokemon = results[i]

            jobject = Json.object_()

            id_ = pokemon[INDEX]
            if id_ > self.last_id:
                self.last_id = id_

            jobject[i_id] = Json(id_)

            point = cellid_to_s2point(<uint64_t>pokemon[SPAWN_ID])
            jobject[i_lat] = Json(s2point_to_lat(point))
            jobject[i_lon] = Json(s2point_to_lon(point))

            pokemon_id = pokemon[POKEMON_ID]

            jobject[i_trash] = Json(self.trash.find(pokemon_id) != self.trash.end())
            jobject[i_name] = Json(self.names[pokemon_id])
            jobject[i_expires] = Json(<int>pokemon[EXPIRATION])

            self.cache.push_back(Json(jobject))

    cdef unicode get_first(self):
        cdef string time_index = string(b'expires_at')
        it = self.cache.begin()
        while it != self.cache.end():
            if deref(it)[time_index].int_value() < int_time():
                self.cache.erase(it)
            else:
                incr(it)
        return Json(self.cache).dump()

    def get_json(self, int last_id):
        if self.last_update + 5 < int_time():
            self.update_cache()

        if last_id == 0:
            return self.get_first()

        cdef:
            Json.array jarray
            Json obj
            string id_index = string(b'id')
            string time_index = string(b'expires_at')

        it = self.cache.begin()
        while it != self.cache.end():
            obj = deref(it)

            if obj[time_index].int_value() < int_time():
                self.cache.erase(it)
            elif obj[id_index].int_value() < last_id:
                incr(it)
            else:
                jarray.push_back(obj)
                incr(it)

        return Json(jarray).dump()
