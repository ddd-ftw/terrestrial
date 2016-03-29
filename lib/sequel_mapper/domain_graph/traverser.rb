require "tsort"

module SequelMapper
  module DomainGraph
    class Traverser
      def initialize(root_vertex)
        @visited_verticies = Set.new([])
        @root_vertex = root_vertex
      end

      attr_reader :root_vertex, :visited_verticies
      private :root_vertex, :visited_verticies

      def vertices
        @vertices ||= get_vertices(root_vertex)
      end

      private

      def get_vertices(vertex)
        return [] if visited_verticies.include?(vertex)

        visited_verticies.add(vertex)

        [vertex] + vertex.each_vertex.flat_map { |other_vertex|
          get_vertices(other_vertex)
        }.to_a
      end
    end
  end
end
