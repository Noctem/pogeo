#ifndef CYTHON_MCPP_EMPLACE_HPP_
#define CYTHON_MCPP_EMPLACE_HPP_

#include <utility>
#include "emplace_detail.hpp"

namespace mcpp {
template <typename container, typename... args>
inline auto emplace(container &c, args &&... Args)
    -> decltype(detail::emplace_dispatch(c, std::forward<args>(Args)...)) {
  return detail::emplace_dispatch(c, std::forward<args>(Args)...);
}

template <typename container, typename... args>
inline auto emplace_move(container &c, args &&... Args)
    -> decltype(emplace(c, std::move(Args)...)) {
  return emplace(c, std::move(Args)...);
}

template <typename container, typename type>
inline auto emplace_object_move(container &v, type &t)
    -> decltype(emplace_move(v, t)) {
  return emplace_move(v, t);
}

template <typename container, typename pos, typename... args>
inline auto emplace_pos_move(container &v, pos p, args &&... Args)
    -> decltype(v.emplace(p, std::move(Args)...)) {
  return v.emplace(p, std::move(Args)...);
}

template <typename container, typename pos, typename type>
inline auto emplace_object_pos_move(container &v, pos p, type &t)
    -> decltype(emplace_pos_move(v, p, std::move(t))) {
  return emplace_pos_move(v, p, std::move(t));
}
}  // namespace mcpp

#endif
