from libcpp cimport bool
from libcpp.pair cimport pair
from libcpp.vector cimport vector


from .s2 cimport S2Point
from .s2loop cimport S2Loop
from .s2polygon cimport S2Polygon


cdef extern from "s2polygonbuilder.h" nogil:

    cdef cppclass S2PolygonBuilderOptions:
        S2PolygonBuilderOptions()
        bool undirected_edges()
        void set_undirected_edges(bool undirected_edges)
        bool xor_edges()
        void set_xor_edges(bool xor_edges)
        bool validate()
        void set_validate(bool validate)
        double edge_splice_fraction()
        void set_edge_splice_fraction(double edge_splice_fraction)

    cdef cppclass S2PolygonBuilder:
        S2PolygonBuilder()
        S2PolygonBuilder(S2PolygonBuilderOptions options)
        bool AddEdge(S2Point v0, S2Point v1)
        void AddLoop(S2Loop* loop)
        void AddPolygon(S2Polygon polygon)
        ctypedef vector[pair[S2Point, S2Point]] EdgeList
        bool AssembleLoops(vector[S2Loop*]* loops, EdgeList* unused_edges)
        bool AssemblePolygon(S2Polygon* polygon, EdgeList* unused_edges)

