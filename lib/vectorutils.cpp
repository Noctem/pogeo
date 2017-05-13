#include <algorithm>
#include <iterator>
#include <string>

#include "json11.hpp"

using std::back_inserter;
using std::copy_if;
using std::remove_if;
using std::string;
using json11::Json;

string dump_after_id(const Json::array &arr, int ind) {
  Json::array jarray;
  copy_if(arr.begin(), arr.end(), back_inserter(jarray),
          [ind](const Json &object) { return object["id"].int_value() > ind; });
  return Json(jarray).dump();
}

void remove_expired(Json::array &arr, int now) {
  arr.erase(std::remove_if(arr.begin(), arr.end(),
                           [now](const Json &object) {
                             return object["expire"].int_value() < now;
                           }),
            arr.end());
}
