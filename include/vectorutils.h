#include <string>

#include "json11.hpp"

using std::string;
using json11::Json;

string dump_after_id(const Json::array &arr, int index);
void remove_expired(Json::array &arr, int now);
