//
// Copyright (C) 1999-2005 Google, Inc.
//

#include <cstdio>
using std::snprintf;

#include <cstdlib>
using std::strtoll;
using std::strtoull;

#include <string>
using std::string;

#include <vector>
using std::vector;

#include "strutil.h"

#include "base/logging.h"
#include "split.h"

// ----------------------------------------------------------------------
// FloatToString()
// IntToString()
//    Convert various types to their string representation.  These
//    all do the obvious, trivial thing.
// ----------------------------------------------------------------------

string FloatToString(float f, const char* format) {
  char buf[80];
  snprintf(buf, sizeof(buf), format, f);
  return string(buf);
}

string IntToString(int i, const char* format) {
  char buf[80];
  snprintf(buf, sizeof(buf), format, i);
  return string(buf);
}

string Int64ToString(int64 i64, const char* format) {
  char buf[80];
  snprintf(buf, sizeof(buf), format, i64);
  return string(buf);
}

string UInt64ToString(uint64 ui64, const char* format) {
  char buf[80];
  snprintf(buf, sizeof(buf), format, ui64);
  return string(buf);
}

// Default arguments
string FloatToString(float f) { return FloatToString(f, "%7f"); }
string IntToString(int i) { return IntToString(i, "%7d"); }
string Int64ToString(int64 i64) {
  return Int64ToString(i64, "%7" GG_LL_FORMAT "d");
}
string UInt64ToString(uint64 ui64) {
  return UInt64ToString(ui64, "%7" GG_LL_FORMAT "u");
}

// ----------------------------------------------------------------------
// FastIntToBuffer()
// FastInt64ToBuffer()
// FastHexToBuffer()
// FastHex64ToBuffer()
// FastHex32ToBuffer()
//    These are intended for speed.  FastHexToBuffer() assumes the
//    integer is non-negative.  FastHexToBuffer() puts output in
//    hex rather than decimal.
//
//    FastHex64ToBuffer() puts a 64-bit unsigned value in hex-format,
//    padded to exactly 16 bytes (plus one byte for '\0')
//
//    FastHex32ToBuffer() puts a 32-bit unsigned value in hex-format,
//    padded to exactly 8 bytes (plus one byte for '\0')
//
//    All functions take the output buffer as an arg.  FastInt() uses at
//    most 22 bytes.  They all return a pointer to the beginning of the
//    output, which may not be the beginning of the input buffer.
// ----------------------------------------------------------------------

char* FastInt64ToBuffer(int64 i, char* buffer) {
  FastInt64ToBufferLeft(i, buffer);
  return buffer;
}

// Offset into buffer where FastInt32ToBuffer places the end of string
// null character.  Also used by FastInt32ToBufferLeft
// static const int kFastInt32ToBufferOffset = 11;

char* FastInt32ToBuffer(int32 i, char* buffer) {
  FastInt32ToBufferLeft(i, buffer);
  return buffer;
}

char* FastHexToBuffer(int i, char* buffer) {
  CHECK(i >= 0) << "FastHexToBuffer() wants non-negative integers, not " << i;

  static const char* hexdigits = "0123456789abcdef";
  char* p = buffer + 21;
  *p-- = '\0';
  do {
    *p-- = hexdigits[i & 15];  // mod by 16
    i >>= 4;                   // divide by 16
  } while (i > 0);
  return p + 1;
}

char* InternalFastHexToBuffer(uint64 value, char* buffer, int num_byte) {
  static const char* hexdigits = "0123456789abcdef";
  buffer[num_byte] = '\0';
  for (int i = num_byte - 1; i >= 0; i--) {
    buffer[i] = hexdigits[uint32(value) & 0xf];
    value >>= 4;
  }
  return buffer;
}

char* FastHex64ToBuffer(uint64 value, char* buffer) {
  return InternalFastHexToBuffer(value, buffer, 16);
}

char* FastHex32ToBuffer(uint32 value, char* buffer) {
  return InternalFastHexToBuffer(value, buffer, 8);
}

// Several converters use this table to reduce
// division and modulo operations.
static const char two_ASCII_digits[100][2] = {
    {'0', '0'}, {'0', '1'}, {'0', '2'}, {'0', '3'}, {'0', '4'}, {'0', '5'},
    {'0', '6'}, {'0', '7'}, {'0', '8'}, {'0', '9'}, {'1', '0'}, {'1', '1'},
    {'1', '2'}, {'1', '3'}, {'1', '4'}, {'1', '5'}, {'1', '6'}, {'1', '7'},
    {'1', '8'}, {'1', '9'}, {'2', '0'}, {'2', '1'}, {'2', '2'}, {'2', '3'},
    {'2', '4'}, {'2', '5'}, {'2', '6'}, {'2', '7'}, {'2', '8'}, {'2', '9'},
    {'3', '0'}, {'3', '1'}, {'3', '2'}, {'3', '3'}, {'3', '4'}, {'3', '5'},
    {'3', '6'}, {'3', '7'}, {'3', '8'}, {'3', '9'}, {'4', '0'}, {'4', '1'},
    {'4', '2'}, {'4', '3'}, {'4', '4'}, {'4', '5'}, {'4', '6'}, {'4', '7'},
    {'4', '8'}, {'4', '9'}, {'5', '0'}, {'5', '1'}, {'5', '2'}, {'5', '3'},
    {'5', '4'}, {'5', '5'}, {'5', '6'}, {'5', '7'}, {'5', '8'}, {'5', '9'},
    {'6', '0'}, {'6', '1'}, {'6', '2'}, {'6', '3'}, {'6', '4'}, {'6', '5'},
    {'6', '6'}, {'6', '7'}, {'6', '8'}, {'6', '9'}, {'7', '0'}, {'7', '1'},
    {'7', '2'}, {'7', '3'}, {'7', '4'}, {'7', '5'}, {'7', '6'}, {'7', '7'},
    {'7', '8'}, {'7', '9'}, {'8', '0'}, {'8', '1'}, {'8', '2'}, {'8', '3'},
    {'8', '4'}, {'8', '5'}, {'8', '6'}, {'8', '7'}, {'8', '8'}, {'8', '9'},
    {'9', '0'}, {'9', '1'}, {'9', '2'}, {'9', '3'}, {'9', '4'}, {'9', '5'},
    {'9', '6'}, {'9', '7'}, {'9', '8'}, {'9', '9'}};

// ----------------------------------------------------------------------
// FastInt32ToBufferLeft()
// FastUInt32ToBufferLeft()
// FastInt64ToBufferLeft()
// FastUInt64ToBufferLeft()
//
// Like the Fast*ToBuffer() functions above, these are intended for speed.
// Unlike the Fast*ToBuffer() functions, however, these functions write
// their output to the beginning of the buffer (hence the name, as the
// output is left-aligned).  The caller is responsible for ensuring that
// the buffer has enough space to hold the output.
//
// Returns a pointer to the end of the string (i.e. the null character
// terminating the string).
// ----------------------------------------------------------------------

char* FastUInt32ToBufferLeft(uint32 u, char* buffer) {
  int digits;
  const char* ASCII_digits = nullptr;
  // The idea of this implementation is to trim the number of divides to as few
  // as possible by using multiplication and subtraction rather than mod (%),
  // and by outputting two digits at a time rather than one.
  // The huge-number case is first, in the hopes that the compiler will output
  // that case in one branch-free block of code, and only output conditional
  // branches into it from below.
  if (u >= 1000000000) {     // >= 1,000,000,000
    digits = u / 100000000;  // 100,000,000
    ASCII_digits = two_ASCII_digits[digits];
    buffer[0] = ASCII_digits[0];
    buffer[1] = ASCII_digits[1];
    buffer += 2;
  sublt100_000_000:
    u -= digits * 100000000;  // 100,000,000
  lt100_000_000:
    digits = u / 1000000;  // 1,000,000
    ASCII_digits = two_ASCII_digits[digits];
    buffer[0] = ASCII_digits[0];
    buffer[1] = ASCII_digits[1];
    buffer += 2;
  sublt1_000_000:
    u -= digits * 1000000;  // 1,000,000
  lt1_000_000:
    digits = u / 10000;  // 10,000
    ASCII_digits = two_ASCII_digits[digits];
    buffer[0] = ASCII_digits[0];
    buffer[1] = ASCII_digits[1];
    buffer += 2;
  sublt10_000:
    u -= digits * 10000;  // 10,000
  lt10_000:
    digits = u / 100;
    ASCII_digits = two_ASCII_digits[digits];
    buffer[0] = ASCII_digits[0];
    buffer[1] = ASCII_digits[1];
    buffer += 2;
  sublt100:
    u -= digits * 100;
  lt100:
    digits = u;
    ASCII_digits = two_ASCII_digits[digits];
    buffer[0] = ASCII_digits[0];
    buffer[1] = ASCII_digits[1];
    buffer += 2;
  done:
    *buffer = 0;
    return buffer;
  }

  if (u < 100) {
    digits = u;
    if (u >= 10) goto lt100;
    *buffer++ = '0' + digits;
    goto done;
  }
  if (u < 10000) {  // 10,000
    if (u >= 1000) goto lt10_000;
    digits = u / 100;
    *buffer++ = '0' + digits;
    goto sublt100;
  }
  if (u < 1000000) {  // 1,000,000
    if (u >= 100000) goto lt1_000_000;
    digits = u / 10000;  //    10,000
    *buffer++ = '0' + digits;
    goto sublt10_000;
  }
  if (u < 100000000) {  // 100,000,000
    if (u >= 10000000) goto lt100_000_000;
    digits = u / 1000000;  //   1,000,000
    *buffer++ = '0' + digits;
    goto sublt1_000_000;
  }
  // we already know that u < 1,000,000,000
  digits = u / 100000000;  // 100,000,000
  *buffer++ = '0' + digits;
  goto sublt100_000_000;
}

char* FastInt32ToBufferLeft(int32 i, char* buffer) {
  uint32 u = i;
  if (i < 0) {
    *buffer++ = '-';
    // We need to do the negation in modular (i.e., "unsigned")
    // arithmetic; MSVC++ apprently warns for plain "-u", so
    // we write the equivalent expression "0 - u" instead.
    u = 0 - u;
  }
  return FastUInt32ToBufferLeft(u, buffer);
}

char* FastUInt64ToBufferLeft(uint64 u64, char* buffer) {
  int digits;
  const char* ASCII_digits = nullptr;

  uint32 u = static_cast<uint32>(u64);
  if (u == u64) return FastUInt32ToBufferLeft(u, buffer);

  uint64 top_11_digits = u64 / 1000000000;
  buffer = FastUInt64ToBufferLeft(top_11_digits, buffer);
  u = u64 - (top_11_digits * 1000000000);

  digits = u / 10000000;  // 10,000,000
  DCHECK_LT(digits, 100);
  ASCII_digits = two_ASCII_digits[digits];
  buffer[0] = ASCII_digits[0];
  buffer[1] = ASCII_digits[1];
  buffer += 2;
  u -= digits * 10000000;  // 10,000,000
  digits = u / 100000;     // 100,000
  ASCII_digits = two_ASCII_digits[digits];
  buffer[0] = ASCII_digits[0];
  buffer[1] = ASCII_digits[1];
  buffer += 2;
  u -= digits * 100000;  // 100,000
  digits = u / 1000;     // 1,000
  ASCII_digits = two_ASCII_digits[digits];
  buffer[0] = ASCII_digits[0];
  buffer[1] = ASCII_digits[1];
  buffer += 2;
  u -= digits * 1000;  // 1,000
  digits = u / 10;
  ASCII_digits = two_ASCII_digits[digits];
  buffer[0] = ASCII_digits[0];
  buffer[1] = ASCII_digits[1];
  buffer += 2;
  u -= digits * 10;
  digits = u;
  *buffer++ = '0' + digits;
  *buffer = 0;
  return buffer;
}

char* FastInt64ToBufferLeft(int64 i, char* buffer) {
  uint64 u = i;
  if (i < 0) {
    *buffer++ = '-';
    u = 0 - u;
  }
  return FastUInt64ToBufferLeft(u, buffer);
}

// ----------------------------------------------------------------------
// ParseLeadingUInt64Value
// ParseLeadingInt64Value
// ParseLeadingHex64Value
//    A simple parser for long long values. Returns the parsed value if a
//    valid integer is found; else returns deflt
//    UInt64 and Int64 cannot handle decimal numbers with leading 0s.
// --------------------------------------------------------------------
uint64 ParseLeadingUInt64Value(const char* str, uint64 deflt) {
  char* error = nullptr;
  const uint64 value = strtoull(str, &error, 0);
  return (error == str) ? deflt : value;
}

int64 ParseLeadingInt64Value(const char* str, int64 deflt) {
  char* error = nullptr;
  const int64 value = strtoll(str, &error, 0);
  return (error == str) ? deflt : value;
}

uint64 ParseLeadingHex64Value(const char* str, uint64 deflt) {
  char* error = nullptr;
  const uint64 value = strtoull(str, &error, 16);
  return (error == str) ? deflt : value;
}

// ----------------------------------------------------------------------
// ParseLeadingDec64Value
// ParseLeadingUDec64Value
//    A simple parser for [u]int64 values. Returns the parsed value
//    if a valid value is found; else returns deflt
//    The string passed in is treated as *10 based*.
//    This can handle strings with leading 0s.
// --------------------------------------------------------------------

int64 ParseLeadingDec64Value(const char* str, int64 deflt) {
  char* error = nullptr;
  const int64 value = strtoll(str, &error, 10);
  return (error == str) ? deflt : value;
}

uint64 ParseLeadingUDec64Value(const char* str, uint64 deflt) {
  char* error = nullptr;
  const uint64 value = strtoull(str, &error, 10);
  return (error == str) ? deflt : value;
}

bool DictionaryParse(const string& encoded_str,
                     vector<pair<string, string> >* items) {
  vector<string> entries;
  SplitStringUsing(encoded_str, ",", &entries);
  for (size_t i = 0; i < entries.size(); ++i) {
    vector<string> fields;
    SplitStringAllowEmpty(entries[i], ":", &fields);
    if (fields.size() != 2)  // parsing error
      return false;
    items->push_back(make_pair(fields[0], fields[1]));
  }
  return true;
}
