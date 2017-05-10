#include "gzip.h"
#include "zlib.h"

#define CHUNK 16384
#define windowBits 15
#define GZIP_ENCODING 16

bool gzip::compress(const std::string &data, std::string &compressedData,
                    int level) {
  unsigned char out[CHUNK];
  z_stream strm;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  if (deflateInit2(&strm, level, Z_DEFLATED, windowBits | GZIP_ENCODING, 8,
                   Z_DEFAULT_STRATEGY) != Z_OK) {
    return false;
  }
  strm.next_in = (unsigned char *)data.c_str();
  strm.avail_in = data.size();
  do {
    int have;
    strm.avail_out = CHUNK;
    strm.next_out = out;
    if (deflate(&strm, Z_FINISH) == Z_STREAM_ERROR) {
      return false;
    }
    have = CHUNK - strm.avail_out;
    compressedData.append((char *)out, have);
  } while (strm.avail_out == 0);
  if (deflateEnd(&strm) != Z_OK) {
    return false;
  }
  return true;
}
