//
// Copyright (C) 2007 and onwards Google, Inc.
//
//
// MacOSX-specific STL help, mirroring examples in stl_decl_msvc.h et
// al.  Although this convention is apparently deprecated (see mec's
// comments in stl_decl_msvc.h), it is the consistent way of getting
// google3 happy on OSX.
//
// Don't include this directly.

#ifndef _STL_DECL_OSX_H
#define _STL_DECL_OSX_H

#if !defined(__APPLE__) || !defined(OS_MACOSX)
#error "This file is only for MacOSX."
#endif

#include <cstddef>
#include <algorithm>
using std::min;
using std::max;
using std::swap;
using std::reverse;

#include <string>
using std::string;

#include <vector>
using std::vector;

#include <functional>
using std::less;

#include <utility>
using std::pair;
using std::make_pair;

#include <set>
using std::set;
using std::multiset;

#include <list>
#include <deque>
#include <iostream>
using std::ostream;
using std::cout;
using std::endl;

#include <map>
using std::map;
using std::multimap;

#include <queue>
using std::priority_queue;

#include <stack>
#include <bits/stl_tempbuf.h>
#include <ios>
#include <string>
using std::string;

#include <functional>
using std::hash;

#include <unordered_set>
using std::unordered_set;

#include <unordered_map>
using std::unordered_map;


using namespace std;
/* On Linux (and gdrive on OSX), this comes from places like
   google3/third_party/stl/gcc3/new.  On OSX using "builtin"
   stl headers, however, it does not get defined. */
#ifndef __STL_USE_STD_ALLOCATORS
#define __STL_USE_STD_ALLOCATORS 1
#endif

#endif  /* _STL_DECL_OSX_H */
