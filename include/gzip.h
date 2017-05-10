#ifndef _GZIP_H_
#define _GZIP_H_

#include <string>

namespace gzip {
// GZip Compression
// @param data - the data to compress (does not have to be string, can be binary
// data)
// @param compressedData - the resulting gzip compressed data
// @param level - the gzip compress level -1 = default, 0 = no compression, 1=
// worst/fastest compression, 9 = best/slowest compression
// @return - true on success, false on failure
bool compress(const std::string& data, std::string& compressedData,
              int level = -1);
}  // namespace gzip

#endif  // _GZIP_H_
