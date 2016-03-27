module SequelMapper
  class DomainGraph
    class Factory
      def initialize(mappings)
        @mappings = mappings
      end

      attr_reader :mappings
      private :mappings

      def call(object, mapping_name)
        mapping = mappings.fetch(mapping_name)

        vertex(object, mapping)
      end

      private

      def vertex(object, mapping)
        Vertex.new(object, mapping, edges(object, mapping))
      end

      def edges(object, mapping)
        _data, association_data = mapping.serialize(object, 0, {})

        mapping.associations.lazy.flat_map { |name, definition|
          Array(association_data.fetch(name)).map { |associated_object|
            call(associated_object, definition.mapping_name)
          }
        }
      end
    end

    class Vertex
      def initialize(object, mapping, edges)
        @object = object
        @mapping = mapping
        @edges = edges
      end

      attr_reader :object, :mapping, :edges
      private :mapping, :edges

      def each_edge(&block)
        edges.each(&block)
      end
    end
  end
end
