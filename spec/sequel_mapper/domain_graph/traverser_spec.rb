require "sequel_mapper/domain_graph"
require "sequel_mapper/domain_graph/traverser"

require "support/object_graph_setup"
require "support/mapper_setup"

RSpec.describe SequelMapper::DomainGraph do
  include_context "object graph setup"
  include_context "mapper setup"

  subject(:traverser) { SequelMapper::DomainGraph::Traverser.new(graph) }

  # let(:graph) {
  #   SequelMapper::DomainGraph::Factory.new(mappings)
  #     .call(:users, hansel)
  # }

  # describe "#vertices" do
  #   it "returns a domain-topologically sorted list of all vertices" do
  #     expect(traverser.vertices.map(&:data).map { |d| d.fetch(:id) }).to eq([
  #       "users/1",
  #       "posts/1",
  #       "posts/2",
  #       "comments/1",
  #       "categories/1",
  #       "categories/2",
  #       "users/2",
  #     ])
  #   end
  # end

  Vertex = Struct.new(:id, :vertices) do
    def each_vertex(&block)
      vertices.each(&block)
    end

    def object
      self
    end

    def hash
      [self.class, id].hash
    end

    def eql?(other)
      [self.class, id] == [other.class, other.id]
    end
  end

  let(:graph) {
    Vertex.new("A", [
      Vertex.new("B", [
        Vertex.new("E", [
          Vertex.new("J", []),
          Vertex.new("G", [
            Vertex.new("J", []),
          ]),
        ]),
        # Vertex.new("C", [
        #   Vertex.new("H", [
        #     Vertex.new("J", []),
        #   ]),
        #   Vertex.new("F", [
        #     Vertex.new("I", [
        #       Vertex.new("H", [
        #         Vertex.new("J", []),
        #       ]),
        #     ]),
        #   ]),
        # ]),
      ]),
      Vertex.new("C", [
        Vertex.new("H", [
          Vertex.new("J", []),
        ]),
        Vertex.new("F", [
          Vertex.new("I", [
            Vertex.new("H", [
              Vertex.new("J", []),
            ]),
          ]),
        ]),
      ]),
      Vertex.new("D", [
        Vertex.new("F", [
          Vertex.new("I", [
            Vertex.new("H", [
              Vertex.new("J", []),
            ]),
          ]),
        ]),
        Vertex.new("I", [
          Vertex.new("H", [
            Vertex.new("J", []),
          ]),
        ]),
      ]),
    ])
  }

  describe "#vertices" do
    it "returns a domain-topologically sorted list of all vertices" do
      expect(traverser.vertices.map(&:id)).to eq(%w(
        A D B C F I H E G J
      ))
    end
  end

  describe "#tsort" do
    it "returns a domain-topologically sorted list of all vertices" do
      expect(traverser.tsort.reverse.map(&:id)).to eq(%w(
        A D B C F I H E G J
      ))
    end
  end
end
