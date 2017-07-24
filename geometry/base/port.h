//
// Copyright (C) 1999 and onwards Google, Inc.

#ifndef BASE_PORT_H_
#define BASE_PORT_H_

#if defined OS_LINUX || defined OS_CYGWIN

// _BIG_ENDIAN
#include <endian.h>

#elif defined OS_FREEBSD

// _BIG_ENDIAN
#include <machine/endian.h>

#elif defined OS_SOLARIS

// _BIG_ENDIAN
#include <sys/isa_defs.h>

#elif defined __APPLE__

// BIG_ENDIAN
#include <machine/endian.h>
/* Let's try and follow the Linux convention */
#define __BYTE_ORDER BYTE_ORDER
#define __LITTLE_ENDIAN LITTLE_ENDIAN
#define __BIG_ENDIAN BIG_ENDIAN

#endif

// The following guarenty declaration of the byte swap functions, and
// define __BYTE_ORDER for MSVC
#if defined(COMPILER_MSVC) || defined(_WIN32)
#define __BYTE_ORDER __LITTLE_ENDIAN
#define bswap_16(x) _byteswap_ushort(x)
#define bswap_32(x) _byteswap_ulong(x)
#define bswap_64(x) _byteswap_uint64(x)
#elif defined(__APPLE__)
// Mac OS X / Darwin features
#include <libkern/OSByteOrder.h>
#define bswap_16(x) OSSwapInt16(x)
#define bswap_32(x) OSSwapInt32(x)
#define bswap_64(x) OSSwapInt64(x)
#elif defined __sun
#include <sys/byteorder.h>
#define bswap_16(x) BSWAP_16(x)
#define bswap_32(x) BSWAP_32(x)
#define bswap_64(x) BSWAP_64(x)
#elif defined __FreeBSD__
#include <sys/endian.h>
#define bswap_16(x) bswap16(x)
#define bswap_32(x) bswap32(x)
#define bswap_64(x) bswap64(x)
#elif defined __OpenBSD__
#include <sys/endian.h>
#define bswap_16(x) swap16(x)
#define bswap_32(x) swap32(x)
#define bswap_64(x) swap64(x)
#else
#include <byteswap.h>
#endif

// define the macros IS_LITTLE_ENDIAN or IS_BIG_ENDIAN
// using the above endian defintions from endian.h if
// endian.h was included
#ifdef __BYTE_ORDER

#if __BYTE_ORDER == __LITTLE_ENDIAN
#define IS_LITTLE_ENDIAN
#endif

#if __BYTE_ORDER == __BIG_ENDIAN
#define IS_BIG_ENDIAN
#endif

#else

#if defined(__LITTLE_ENDIAN__)
#define IS_LITTLE_ENDIAN
#elif defined(__BIG_ENDIAN__)
#define IS_BIG_ENDIAN
#endif

// there is also PDP endian ...

#endif  // __BYTE_ORDER

#if (defined(COMPILER_GCC3) || defined(COMPILER_ICC) || defined(__APPLE__))

//
// Tell the compiler to do printf format string checking if the
// compiler supports it; see the 'format' attribute in
// <http://gcc.gnu.org/onlinedocs/gcc-4.3.0/gcc/Function-Attributes.html>.
//
// N.B.: As the GCC manual states, "[s]ince non-static C++ methods
// have an implicit 'this' argument, the arguments of such methods
// should be counted from two, not one."
//
#define PRINTF_ATTRIBUTE(string_index, first_to_check) \
  __attribute__((__format__(__printf__, string_index, first_to_check)))

//
// Prevent the compiler from padding a structure to natural alignment
//
#define PACKED __attribute__((packed))

#else  // not GCC, clang, or ICC

#define PRINTF_ATTRIBUTE(string_index, first_to_check)
#define PACKED

#endif  // GCC

// x86 and x86-64 can perform unaligned loads/stores directly;
// modern PowerPC hardware can also do unaligned integer loads and stores;
// but note: the FPU still sends unaligned loads and stores to a trap handler!

#define UNALIGNED_LOAD16(_p) (*reinterpret_cast<const uint16*>(_p))
#define UNALIGNED_LOAD32(_p) (*reinterpret_cast<const uint32*>(_p))
#define UNALIGNED_LOAD64(_p) (*reinterpret_cast<const uint64*>(_p))

#define UNALIGNED_STORE16(_p, _val) (*reinterpret_cast<uint16*>(_p) = (_val))
#define UNALIGNED_STORE32(_p, _val) (*reinterpret_cast<uint32*>(_p) = (_val))
#define UNALIGNED_STORE64(_p, _val) (*reinterpret_cast<uint64*>(_p) = (_val))

// printf macros for size_t, in the style of inttypes.h
#ifdef _LP64
#define __PRIS_PREFIX "z"
#else
#define __PRIS_PREFIX
#endif

// Use these macros after a % in a printf format string
// to get correct 32/64 bit behavior, like this:
// size_t size = records.size();
// printf("%"PRIuS"\n", size);

#define PRIdS __PRIS_PREFIX "d"
#define PRIxS __PRIS_PREFIX "x"
#define PRIuS __PRIS_PREFIX "u"
#define PRIXS __PRIS_PREFIX "X"
#define PRIoS __PRIS_PREFIX "o"

#endif  // BASE_PORT_H_
