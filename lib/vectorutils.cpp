#include <algorithm>
#include <iterator>
#include <string>

#include "json11.hpp"

using std::back_inserter;
using std::copy_if;
using std::remove_if;
using std::string;
using json11::Json;

void dump_after_id(const Json::array &arr, int id, string &output) {
  Json::array jarray;
  copy_if(arr.begin(), arr.end(), back_inserter(jarray),
          [id](const Json &object) { return object["id"].int_value() > id; });
  Json(jarray).dump(output);
}

string dump_after_id(const Json::array &arr, int id) {
  Json::array jarray;
  copy_if(arr.begin(), arr.end(), back_inserter(jarray),
          [id](const Json &object) { return object["id"].int_value() > id; });
  return Json(jarray).dump();
}

void remove_expired(Json::array &arr, int now) {
  arr.erase(std::remove_if(arr.begin(), arr.end(),
                           [now](const Json &object) {
                             return object["expire"].int_value() < now;
                           }),
            arr.end());
}
