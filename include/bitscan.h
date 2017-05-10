#ifndef BIT_SCAN_H
#define BIT_SCAN_H

#ifdef __has_builtin
#define HAS_BUILTIN(x) __has_builtin(x)
#else
#define HAS_BUILTIN(x) 0
#endif

#if __GNUC__ >= 4 || HAS_BUILTIN(__builtin_clzll)
#define leadingZeros(x) __builtin_clzll(x)
#endif

#ifndef leadingZeros
#ifdef _MSC_VER
#include <intrin.h>
#ifdef __LZCNT__ && !defined(DEPLOYMENT)
#define leadingZeros(x) __lzcnt64(x)
#else
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
#endif  // __LZCNT__
#else
inline unsigned long leadingZeros(unsigned long long x) {
  unsigned long r = 0;
  while (x >>= 1) r++;
  return 64 - r;
}
#endif  // _MSC_VER
#endif  // leadingZeros

#endif  // BIT_SCAN_H
