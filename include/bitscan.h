#ifndef BIT_SCAN_H
#define BIT_SCAN_H

#ifdef __has_builtin
#define HAS_BUILTIN(x) __has_builtin(x)
#else
#define HAS_BUILTIN(x) 0
#endif

#if __GNUC__ >= 4 || HAS_BUILTIN(__builtin_clzll)
#define leadingZeros(x) __builtin_clzll(x)
#define trailingZeros(x) __builtin_ctzll(x)
#endif

#ifndef leadingZeros
#ifdef _MSC_VER
#include <intrin.h>
inline unsigned long leadingZeros(unsigned __int64 x) {
  unsigned long result;
#ifdef _WIN64
  _BitScanReverse64(&result, x);
#else
  // Scan the high 32 bits.
  if (_BitScanReverse(&result, static_cast<unsigned long>(x >> 32)))
    return 63 - (result + 32);

  // Scan the low 32 bits.
  _BitScanReverse(&result, static_cast<unsigned long>(x));
#endif  // _WIN64
  return 63 - result;
}

inline unsigned long trailingZeros(unsigned __int64 x) {
  unsigned long result;
#ifdef _WIN64
  _BitScanForward64(&result, x);
  return result;
#else
  // Scan the Low Word.
  if (_BitScanForward(&result, static_cast<unsigned long>(x))) return result;

  // Scan the High Word.
  _BitScanForward(&result, static_cast<unsigned long>(x >> 32));
  return result + 32;
#endif  // _WIN64
}
#else
inline unsigned long leadingZeros(unsigned long long x) {
  unsigned long r = 0;
  while (x >>= 1) r++;
  return 64 - r;
}

inline unsigned long trailingZeros(unsigned long long x) {
  unsigned long r;
  for (r = 0; x != 0; x >>= 1) {
    if (x & 01)
      break;
    else
      r++;
  }
  return r;
}
#endif  // _MSC_VER
#endif  // leadingZeros

#endif  // BIT_SCAN_H
