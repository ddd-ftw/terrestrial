
require "spec_helper"

require "sequel_mapper"
require "support/database_fixture"

RSpec.describe "Graph persistence" do
  include SequelMapper::DatabaseFixture

  subject(:mapper) { mapper_fixture }

  let(:user) {
    mapper.where(id: "user/1").fetch(0)
  }

  context "when modifying the root node" do
    let(:modified_email) { "modified@example.com" }

    context "and only the root node" do
      before do
        user.email = modified_email
      end

      it "performs 1 update" do
        expect {
          mapper.save(user)
        }.to change { query_counter.update_count }.by(1)
      end
    end
  end

  context "when modifying a directly associated (has many) object" do
    let(:modified_post_subject) { "modified post subject" }

    before do
      user.posts.first.subject = modified_post_subject
    end

    it "performs 1 updates" do
      expect {
        mapper.save(user)
      }.to change { query_counter.update_count }.by(1)
    end
  end

  context "when loading many nodes of the graph" do
    let(:leaf_node) {
      user.posts.first.comments.first
    }

    before do
      leaf_node
    end

    context "and modifying an intermediate node" do
      let(:post) { leaf_node.post }

      before do
        post.subject = "MODIFIED"
      end

      it "performs 1 write" do
        expect {
          mapper.save(user)
        }.to change { query_counter.update_count }.by(1)
      end
    end

    context "and modifying a leaf node" do
      let(:comment) { leaf_node }

      before do
        comment.body = "UPDATED!"
      end

      it "performs 1 update" do
        expect {
          mapper.save(user)
        }.to change { query_counter.update_count }.by(1)
      end
    end

    context "and modifying both a leaf and intermediate node" do
      let(:post) { leaf_node.post }
      let(:comment) { leaf_node }

      before do
        comment.body = "UPDATED!"
        post.subject = "MODIFIED"
      end

      it "performs 2 updates" do
        expect {
          mapper.save(user)
        }.to change { query_counter.update_count }.by(2)
      end
    end
  end

  context "when modifying a many to many association" do
    let(:post) { user.posts.first }
    let(:category) { post.categories.first }

    before do
      category.name = "UPDATED"
    end

    it "performs 1 write" do
        expect {
          mapper.save(user)
        }.to change { query_counter.update_count }.by(1)
    end
  end

  after do |ex|
    query_counter.show_queries if ex.exception
  end
end
