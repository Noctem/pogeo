#include <algorithm>
#include <string>

#include "json11.hpp"

using std::copy_if;
using std::remove_if;
using std::string;
using json11::Json;

string dump_after_id(const Json::array &arr, int id) {
  Json::array jarray;
  copy_if(arr.cbegin(), arr.cend(), jarray.begin(),
          [id](const Json &object) { return object[string("id")] > id; });
  return Json(jarray).dump();
}

void remove_expired(Json::array &arr, int now) {
  arr.erase(std::remove_if(arr.begin(), arr.end(),
                           [now](const Json &object) {
                             return object[string("expire")] < now;
                           }),
            arr.end());
}
