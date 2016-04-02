
# Ah it's OK I got this one myself. It's pretty late at night but I get it now!
# I'll leave this here in case anyone is interested. I've added the
# explaination below


# This is some code I wrote as excercise after watching
# https://youtu.be/QnWDU1wcsPA?t=470
#
# The first example mimics the result from the video and is there just to
# verify my use of the TSort module is correct.
#
# In the second example I modified to graph to more closely reflect a problem
# I'm working on by removing the edge b -> c. I didn't expect this to change
# the sort order of the first four vertices A, B, C, D.
#
# Instead now F is in the first four vertices and B is bumped down the list
# significantly despite being directly connected to the root vertex.


# Explaination: Topological sort only ensures that all 'shallower' vertices
# that must be traversed in order to reach 'deeper' vertices appear later in
# the order. H is not therefore a shallower or more primary node than B, the
# only constraint for validity of the sort order is that B preceeds E which
# must preceed G and J.


require "tsort"

RSpec.describe "Tarjan's algorithm topological sorting" do

  let(:a) { Vertex.new("A", [b, c, d]) }
  let(:b) { Vertex.new("B", [e, c]) }
  let(:c) { Vertex.new("C", [f, h]) }
  let(:d) { Vertex.new("D", [f, i]) }
  let(:e) { Vertex.new("E", [g, j]) }
  let(:f) { Vertex.new("F", [i]) }
  let(:g) { Vertex.new("G", [j]) }
  let(:h) { Vertex.new("H", [j]) }
  let(:i) { Vertex.new("I", [h]) }
  let(:j) { Vertex.new("J", []) }

  describe "tsort as in youtube example" do
    it "returns a topologically sorted list of all vertices" do
      expect(Traverser.new(a).tsort.reverse.map(&:id))
        .to eq(["A", "D", "B", "C", "F", "I", "H", "E", "G", "J"])
    end
  end

  context "when an edge is removed from b->c" do
    let(:b) { Vertex.new("B", [e]) }

    it "bumps B way down the sort order!" do
      expect(Traverser.new(a).tsort.reverse.map(&:id))
        .to eq(["A", "D", "C", "F", "I", "H", "B", "E", "G", "J"])
    end
  end

  Vertex = Struct.new(:id, :vertices)

  class Traverser
    include TSort

    def initialize(root)
      @root = root
    end

    def tsort_each_node(&block)
      [@root].each(&block)
    end

    def tsort_each_child(node, &block)
      node.vertices.each(&block)
    end
  end
end
