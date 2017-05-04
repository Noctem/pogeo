#ifdef _MSC_VER
#include <intrin.h>
unsigned int bitScanReverse(unsigned long long x) {
  unsigned long result;
  _BitScanReverse64(&result, val);
  return result;
}
#elif __has_builtin(__builtin_clzll) || defined(__GNUC__)
unsigned int bitScanReverse(unsigned long long x) { return __builtin_clzll(x); }
#else
unsigned int bitScanReverse(unsigned long long x) {
  unsigned long r = 0;
  while (x >>= 1)
    r++;
  return 64 - r;
}
#endif // _MSC_VER
