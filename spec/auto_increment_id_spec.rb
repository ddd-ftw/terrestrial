require "spec_helper"
require "support/object_store_setup"
require "support/sequel_persistence_setup"
require "support/have_persisted_matcher"

RSpec.describe "Auto increment database ids" do
  include_context "object store setup"
  include_context "sequel persistence setup"

  before(:all) do
    create_auto_increment_schema
  end

  after(:all) do
    drop_auto_increment_tables
  end

  before do
    mutate_configs_for_auto_increment
  end

  let(:user) { User.new(user_attrs) }

  let(:user_attrs) {
    {
      id: Terrestrial::AutoInteger.new,
      first_name: "Hansel",
      last_name: "Trickett",
      email: "hansel@tricketts.org",
      posts: [],
    }
  }

  it "persists the root node" do
    user_store.save(user)

    expect(datastore).to have_persisted(
      :auto_users,
      hash_including(
        id: an_instance_of(Fixnum),
        first_name: hansel.first_name,
        last_name: hansel.last_name,
        email: hansel.email,
      )
    )
  end

  it "updates the object auto id" do
    user_store.save(user)

    expect(user.id.value).to match(Fixnum)
  end

  context "when persisting two associated objects" do
    before { user.posts.push(post) }

    let(:post) { Post.new(post_attrs) }

    let(:post_attrs) {
      {
        id: Terrestrial::AutoInteger.new,
        subject: "Biscuits",
        body: "I like them",
        comments: [],
        categories: [],
        created_at: Time.parse("2015-09-05T15:00:00+01:00"),
      }
    }

    it "persists both objects" do
      user_store.save(user)

      expect(datastore).to have_persisted(
        :auto_users,
        hash_including(
          id: an_instance_of(Fixnum),
          first_name: hansel.first_name,
          last_name: hansel.last_name,
          email: hansel.email,
        )
      )

      expect(datastore).to have_persisted(
        :auto_posts,
        hash_including(
          id: an_instance_of(Fixnum),
          subject: "Biscuits",
          body: "I like them",
          created_at: Time.parse("2015-09-05T15:00:00+01:00"),
        )
      )
    end

    it "backfills both ids" do
      user_store.save(user)

      expect(user.id.value).to match(Fixnum)
      expect(post.id.value).to match(Fixnum)
    end

    it "writes the foreign key" do
      user_store.save(user)

      expect(datastore[:auto_posts].first.fetch(:author_id)).to eq(user.id)
    end
  end

  def drop_auto_increment_tables
    Terrestrial::SequelTestSupport.drop_tables(auto_increment_schema.fetch(:tables).keys)
  end

  def create_auto_increment_schema
    Terrestrial::SequelTestSupport.create_tables(auto_increment_schema)
  end

  def auto_increment_schema
    BLOG_SCHEMA.merge(
      tables: Hash[BLOG_SCHEMA.fetch(:tables).map { |name, columns|
        [
          "auto_" + name.to_s,
          columns.map { |props|
            if props.fetch(:name) == :id
              props.merge(integer_primary_key_opts)
            elsif props.fetch(:name).to_s.end_with?("_id")
              props.merge(integer_field_type_opts)
            else
              props
            end
          },
        ]
      }],
    )
  end

  def mutate_configs_for_auto_increment
    configs.merge!(
      Hash[configs.map { |mapping_name, config|
        auto_fields = configs.fetch(mapping_name).fetch(:fields).include?(:id) ?  [:id] : []

        [
          mapping_name,
          config.merge(
            namespace: ("auto_" + configs.fetch(mapping_name).fetch(:namespace).to_s).to_sym,
            auto: auto_fields,
          )
        ]
      }]
    )
  end

  def integer_field_type_opts
    {
      type: Integer,
    }
  end

  def integer_primary_key_opts
    {
      type: Integer,
      options: {
        primary_key: true,
        serial: true,
      }
    }
  end
end
