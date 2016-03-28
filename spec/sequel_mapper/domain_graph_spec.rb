require "sequel_mapper/domain_graph"

require "support/object_graph_setup"
require "support/mapper_setup"

RSpec.describe SequelMapper::DomainGraph do
  include_context "object graph setup"
  include_context "mapper setup"

  subject(:transformed_graph) {
    SequelMapper::DomainGraph::Factory.new(mappings)
      .call(domain_root, domain_root_mapping_name)
  }

  let(:domain_root) { hansel }
  let(:first_level_domain_objects) { domain_root.posts.to_a }
  let(:second_level_domain_objects) {
    first_level_domain_objects.map { |o| [o.categories, o.comments] }.flatten
  }

  let(:domain_root_mapping_name) { :users }

  it "exposes the root domain object via the root vertex" do
    expect(transformed_graph.object).to eq(domain_root)
  end

  it "allows shallow traversal of edges" do
    expect(
      transformed_graph.each_edge.map(&:object).to_a
    ).to eq(first_level_domain_objects)
  end

  it "allows deep traversal of edges" do
    expect(
      transformed_graph.each_edge.flat_map(&:each_edge).map(&:object)
    ).to match_array(second_level_domain_objects)
  end

  describe SequelMapper::DomainGraph::Vertex do
    describe "hash equality" do
      context "two vertices contain same domain object" do
        let(:hash_map) { {} }
        let(:domain_object) { double(:domain_object) }
        let(:mapping) { double(:mapping) }

        let(:v1) { SequelMapper::DomainGraph::Vertex.new(domain_object, mapping, []) }
        let(:v2) { SequelMapper::DomainGraph::Vertex.new(domain_object, mapping, []) }
        let(:first_value) { double(:first_value) }
        let(:second_value) { double(:second_value) }

        it "hashes to the same key" do
          hash_map.store(v1, first_value)
          hash_map.store(v2, second_value)

          expect(hash_map.keys).to eq([v1])
          expect(hash_map.values).to eq([second_value])

          expect(hash_map.fetch(v1)).to eq(second_value)
          expect(hash_map.fetch(v2)).to eq(second_value)
        end
      end
    end
  end
end
