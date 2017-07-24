// Copyright 2005 Google Inc. All Rights Reserved.

#ifndef UTIL_GEOMETRY_S2POINTREGION_H__
#define UTIL_GEOMETRY_S2POINTREGION_H__

#include "base/logging.h"
#include "base/macros.h"
#include "s2.h"
#include "s2cap.h"
#include "s2latlngrect.h"
#include "s2region.h"

class S2Cell;

// An S2PointRegion is a region that contains a single point.  It is more
// expensive than the raw S2Point type and is useful mainly for completeness.
class S2PointRegion : public S2Region {
 public:
  // Create a region containing the given point, which must be unit length.
  inline explicit S2PointRegion(S2Point const& point);

  ~S2PointRegion() override;

  S2Point const& point() const { return point_; }

  ////////////////////////////////////////////////////////////////////////
  // S2Region interface (see s2region.h for details):

  S2PointRegion* Clone() const override;
  S2Cap GetCapBound() const override;
  S2LatLngRect GetRectBound() const override;
  bool Contains(S2Cell const& cell) const override { return false; }
  bool MayIntersect(S2Cell const& cell) const override;
  bool VirtualContainsPoint(S2Point const& p) const override {
    return Contains(p);
  }
  bool Contains(S2Point const& p) const { return (point_ == p); }
  void Encode(Encoder* const encoder) const;
  bool Decode(Decoder* const decoder);

 private:
  S2Point point_;

  DISALLOW_EVIL_CONSTRUCTORS(S2PointRegion);
};

S2PointRegion::S2PointRegion(S2Point const& point) : point_(point) {
  DCHECK(S2::IsUnitLength(point));
}

#endif  // UTIL_GEOMETRY_S2POINTREGION_H__
