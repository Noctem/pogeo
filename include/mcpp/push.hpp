#ifndef CYTHON_MCPP_PUSH_BACK_HPP_
#define CYTHON_MCPP_PUSH_BACK_HPP_

#include <utility>

namespace mcpp {
template <typename container, typename type>
inline auto push_back_move(container &c, type &t)
    -> decltype(c.push_back(std::move(t))) {
  return c.push_back(std::move(t));
}

template <typename container, typename type>
inline auto push_front_move(container &c, type &t)
    -> decltype(c.push_front(std::move(t))) {
  return c.push_front(std::move(t));
}
}  // namespace mcpp

#endif
