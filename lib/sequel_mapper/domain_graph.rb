module SequelMapper
  module DomainGraph
    class Factory
      def initialize(mappings)
        @mappings = mappings
      end

      attr_reader :mappings
      private :mappings

      def call(mapping_name, object)
        mapping = mappings.fetch(mapping_name)

        vertex(mapping, object)
      end

      private

      def vertex(mapping, object)
        data, association_data = mapping.serialize(object, 0, {})

        Vertex.new(mapping, object, data, edges(mapping, association_data))
      end

      def edges(mapping, association_data)
        mapping.associations.lazy.flat_map { |name, definition|
          Array(association_data.fetch(name)).map { |associated_object|
            Edge.new(
              metadata: definition,
              vertex: call(definition.mapping_name, associated_object)
            )
          }
        }
      end
    end

    class Edge
      def initialize(metadata:, vertex:)
        @metadata = metadata
        @vertex = vertex
      end

      attr_reader :metadata, :vertex
    end

    class Vertex
      def initialize(mapping, object, data, edges)
        @mapping = mapping
        @object = object
        @data = data
        @edges = edges
      end

      attr_reader :mapping, :object, :edges
      private :mapping, :edges

      def data
        @data.to_h
      end

      def hash
        [self.class, object].hash
      end

      def eql?(other)
        [self.class, object] == [other.class, other.object]
      end

      def each_vertex(&block)
        edges.map(&:vertex).each(&block)
      end
    end
  end
end
