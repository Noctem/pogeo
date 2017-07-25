cdef extern from "container.hpp" namespace "mcpp" nogil:
    # Use case: T is a unique_ptr, or other move-only type
    void emplace_object_move[CONTAINER, TYPE](CONTAINER &c, TYPE & t)
    # c.push_back(std::move(t))
    void push_back_move[CONTAINER, TYPE](CONTAINER &c, TYPE &t)
    # c.push_front(std::move(t))
    void push_front_move[CONTAINER, TYPE](CONTAINER &c, TYPE &t)
    # c.emplace(p,std::move(t))
    POS emplace_object_pos_move[CONTAINER, POS, TYPE](CONTAINER &c, POS p, TYPE &t)

    # Create version of emplace and emplace_move
    # that take constructor arguments. We
    # declare the functions as variadic (using ...)
    # The variadic arguments represent constructor
    # parameters for container::value_type
    void emplace[container](container &, ...)
    void emplace_move[container](container &, ...)
    POS emplace_pos_move[CONTAINER, POS](CONTAINER &, POS, ...)
