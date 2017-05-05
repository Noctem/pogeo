# distutils: language = c++
# cython: language_level=3, cdivision=True, c_string_type=str, c_string_encoding=utf-8

from libc.stdint cimport int16_t, uint64_t
from libcpp.set cimport set
from libcpp.string cimport string

from cython.operator cimport preincrement as incr, dereference as deref

from .geo.s2 cimport S2Point
from .libcpp_ cimport remove_if
from .json cimport Json
from .utils cimport int_time, cellid_to_s2point, s2point_to_lat, s2point_to_lon

from contextlib import contextmanager


cdef class WebCache:
    def __cinit__(self, set[int16_t] trash, object names, tuple query, object session_maker):
        self.trash = trash
        self.names = {k: v.encode('utf-8') for k,v in names.items()}
        self.query = query
        self.last_update = 0
        self.session_maker = session_maker

    cdef void update_cache(self):
        cdef:
            Json.object_ jobject
            S2Point point
            int id_
            int16_t pokemon_id
            object pokemons

        self.last_update = int_time()
        with self.session() as session:
            pokemons = session.query(*self.query).filter(self.query[3] > self.last_update, self.query[0] > self.last_id)
            for pokemon in pokemons:
                jobject = Json.object_()

                id_ = pokemon.id
                if id_ > self.last_id:
                    self.last_id = id_

                jobject[string(<char *>'id')] = Json(id_)

                point = cellid_to_s2point(<uint64_t>pokemon.spawn_id)
                jobject[string(<char *>'lat')] = Json(s2point_to_lat(point))
                jobject[string(<char *>'lon')] = Json(s2point_to_lon(point))

                pokemon_id = pokemon.pokemon_id

                jobject[string(<char *>'trash')] = Json(self.trash.find(pokemon_id) != self.trash.end())
                jobject[string(<char *>'name')] = Json(self.names[pokemon_id])
                jobject[string(<char *>'expires_at')] = Json(<int>pokemon.expire_timestamp)

                self.cache.push_back(Json(jobject))

    cdef string get_first(self):
        cdef string time_index = string(<char *>'expires_at')
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
            string id_index = string(<char *>'id')
            string time_index = string(<char *>'expires_at')

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

    @contextmanager
    def session(self):
        """Provide a transactional scope around a series of operations."""
        session = self.session_maker(autoflush=False)
        try:
            yield session
        except Exception:
            session.rollback()
        finally:
            session.close()
