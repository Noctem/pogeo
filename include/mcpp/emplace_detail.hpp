#ifndef CYTHON_MCPP_CONTAINER_DETAIL_HPP_
#define CYTHON_MCPP_CONTAINER_DETAIL_HPP_

#include <utility>

namespace mcpp {
namespace detail {
template <typename T, typename... Args>
auto emplace_impl(int, T &c, Args &&... pp)
    -> decltype(c.emplace_back(std::forward<Args>(pp)...)) {
  return c.emplace_back(std::forward<Args>(pp)...);
}

template <typename T, typename... Args>
auto emplace_impl(long, T &c, Args &&... pp)
    -> decltype(c.emplace(std::forward<Args>(pp)...)) {
  return c.emplace(std::forward<Args>(pp)...);
}

template <typename T, typename... Args>
auto emplace_dispatch(T &c, Args &&... pp)
    -> decltype(detail::emplace_impl(0, c, std::forward<Args>(pp)...)) {
  return detail::emplace_impl(0, c, std::forward<Args>(pp)...);
}
}  // namespace detail
}  // namespace mcpp
#endif
