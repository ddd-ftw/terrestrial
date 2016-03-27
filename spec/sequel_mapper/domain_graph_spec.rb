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
end
