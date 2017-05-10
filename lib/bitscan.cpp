#if defined(_MSC_VER) && defined(_WIN64)
#include <intrin.h>
unsigned int bitScanReverse(unsigned __int64 x) {
  unsigned long result;
  _BitScanReverse64(&result, x);
  return result;
}
#elif defined(__GNUC__)
unsigned int bitScanReverse(unsigned long long x) { return __builtin_clzll(x); }
#elif __has_builtin(__builtin_clzll)
unsigned int bitScanReverse(unsigned long long x) { return __builtin_clzll(x); }
#else
unsigned int bitScanReverse(unsigned long long x) {
  unsigned int r = 0;
  while (x >>= 1) r++;
  return 64 - r;
}
#endif  // _MSC_VER
