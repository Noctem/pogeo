//
// Copyright 2003 Google, Inc.
//
//
// A simple class to handle 3x3 matrices
// The aim of this class is to be able to manipulate 3x3 matrices
// and 3D vectors as naturally as possible and make calculations
// readable.
// For that reason, the operators +, -, * are overloaded.
// (Reading a = a + b*2 - c is much easier to read than
// a = Sub(Add(a, Mul(b,2)),c)   )
// This file only define the typenames, for API details, look into
// matrix3x3-inl.h
//

#ifndef UTIL_MATH_MATRIX3X3_H__
#define UTIL_MATH_MATRIX3X3_H__

template <class VType>
class Matrix3x3;

using Matrix3x3_i = Matrix3x3<int>;
using Matrix3x3_f = Matrix3x3<float>;
using Matrix3x3_d = Matrix3x3<double>;

#endif  // UTIL_MATH_MATRIX3X3_H__
