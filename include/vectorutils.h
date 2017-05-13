#include <string>

#include "json11.hpp"

using std::string;
using json11::Json;

void dump_after_id(const Json::array &arr, int id, string &output);
string dump_after_id(const Json::array &arr, int id);
void remove_expired(Json::array &arr, int now);
