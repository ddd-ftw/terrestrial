require "sequel_mapper/domain_graph"
require "sequel_mapper/domain_graph/traverser"

require "support/object_graph_setup"
require "support/mapper_setup"

RSpec.describe SequelMapper::DomainGraph do
  include_context "object graph setup"
  include_context "mapper setup"

  subject(:traverser) { SequelMapper::DomainGraph::Traverser.new(graph) }

  let(:graph) {
    SequelMapper::DomainGraph::Factory.new(mappings)
      .call(:users, hansel)
  }

  describe "#vertices" do
    it "returns a topologically sorted list of all vertices" do
      expect(traverser.vertices.map(&:data)).to match_array([
        hash_including(id: "users/1"),
        hash_including(id: "posts/1"),
        hash_including(id: "posts/2"),
        hash_including(id: "comments/1"),
        hash_including(id: "categories/1"),
        hash_including(id: "categories/2"),
      ])
    end
  end
end
