require "tsort"

module SequelMapper
  module DomainGraph
    class Traverser
      include TSort

      def initialize(root_vertex)
        @visited_verticies = Set.new([])
        @root_vertex = root_vertex
        @result = []
      end

      def tsort_each_node(&block)
        [root_vertex].each(&block)
      end

      def tsort_each_child(node, &block)
        node.vertices.each(&block)
      end

      attr_reader :root_vertex, :visited_verticies
      private :root_vertex, :visited_verticies

      def vertices
        @vertices ||= get_vertices(root_vertex)
        @result
      end

      private

      def get_vertices(vertex)
        return if visited_verticies.include?(vertex)

        vertex.each_vertex { |child| get_vertices(child) }

        visited_verticies.add(vertex)

        @result.unshift(vertex)
        puts [vertex.object.id, "-", vertex.each_vertex.map(&:object).map(&:id), "\t\t", @result.map(&:id).to_a].flatten.join(" ")
        nil
      end
## J - 		      J
## G - J 		    G J
## E - J G 		  E G J
## B - E 		    B E G J
## H - J 		    H B E G J
## I - H 		    I H B E G J
## F - I 		    F I H B E G J
## C - H F 		  C F I H B E G J
## D - F I 		  D C F I H B E G J
## A - B C D 		A D C F I H B E G J
# got: ["A", "D", "C", "F", "I", "H", "B", "E", "G", "J"]
    end
  end
end
