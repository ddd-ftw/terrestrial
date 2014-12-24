require "support/mock_sequel"
require "sequel_mapper/struct_factory"

module SequelMapper
  module DatabaseFixture
    include SequelTestSupport

    # A little hack so these let blocks from an RSpec example don't have
    # to change
    def self.let(name, &block)
      define_method(name) {
        instance_variable_get("@#{name}") or
          instance_variable_set("@#{name}", instance_eval(&block))
      }
    end

    # TODO: perhaps split this file up

    # Domain objects (POROs)
    User = Struct.new(:id, :first_name, :last_name, :email, :posts, :toots)
    Post = Struct.new(:id, :author, :subject, :body, :comments, :categories)
    Comment = Struct.new(:id, :post, :commenter, :body)
    Category = Struct.new(:id, :name, :posts)
    Toot = Struct.new(:id, :tooter, :body, :tooted_at)

    # A factory per Struct
    # The factories serve two purposes
    #   1. Decouple the mapper from the actual class it instantiates so this can be changed at will
    #   2. The mapper has a hash of symbols => values and Stucts take positional arguments
    let(:user_factory){
      SequelMapper::StructFactory.new(User)
    }

    let(:post_factory){
      SequelMapper::StructFactory.new(Post)
    }

    let(:comment_factory){
      SequelMapper::StructFactory.new(Comment)
    }

    let(:category_factory){
      SequelMapper::StructFactory.new(Category)
    }

    let(:toot_factory){
      SequelMapper::StructFactory.new(Toot)
    }

    let(:datastore) {
      db_connection.tap { |db|
        # When using the standard fixutres we need the fixture data loaded
        # before the connection should be used
        load_fixture_data(db)

        # The query_counter will let us make assertions about how efficiently
        # the database is being used
        db.loggers << query_counter
      }
    }

    let(:query_counter) {
      SequelTestSupport::QueryCounter.new
    }

    def mapper_fixture
      SequelMapper.mapper(
        top_level_namespace: :users,
        datastore: datastore,
        mappings: mapper_config,
      )
    end

    def load_fixture_data(datastore)
      fixture_tables_hash.each do |table_name, rows|

        datastore.drop_table?(table_name)

        datastore.create_table(table_name) do
          # Create each column as a string type.
          # This will suffice for current tests.
          rows.first.keys.each do |column|
            String column
          end
        end

        rows.each do |row|
          datastore[table_name].insert(row)
        end
      end
    end

    # This is a sample of the kind of config SequelMapper needs.
    # For the moment this must be written manually but could be generated from
    # the schema. Automatic config generation is absolutley part of the
    # project roadmap.
    #
    # Config must include an entry for each table with columns and
    # associations. Associations need not be two way but are setup
    # symmetrically here for illustrative purposes.

    let(:mapper_config) {
      {
        users: {
          columns: [
            :id,
            :first_name,
            :last_name,
            :email,
          ],
          factory: user_factory,
          has_many: {
            posts: {
              relation_name: :posts,
              foreign_key: :author_id,
            },
            toots: {
              relation_name: :toots,
              foreign_key: :tooter_id,
              order_by: {
                columns: [:tooted_at],
                direction: :desc,
              },
            },
          },
          # TODO: maybe combine associations like this
          # has_many_through: {
          #   categories_posted_in: {
          #     through_association: [ :posts, :categories ]
          #   }
          # }
        },
        posts: {
          columns: [
            :id,
            :subject,
            :body,
          ],
          factory: post_factory,
          has_many: {
            comments: {
              relation_name: :comments,
              foreign_key: :post_id,
            },
          },
          has_many_through: {
            categories: {
              through_relation_name: :categories_to_posts,
              relation_name: :categories,
              foreign_key: :post_id,
              association_foreign_key: :category_id,
            }
          },
          belongs_to: {
            author: {
              relation_name: :users,
              foreign_key: :author_id,
            },
          },
        },
        comments: {
          columns: [
            :id,
            :body,
          ],
          factory: comment_factory,
          belongs_to: {
            post: {
              relation_name: :posts,
              foreign_key: :post_id,
            },
            commenter: {
              relation_name: :users,
              foreign_key: :commenter_id,
            },
          },
        },
        categories: {
          columns: [
            :id,
            :name,
          ],
          factory: category_factory,
          has_many_through: {
            posts: {
              through_relation_name: :categories_to_posts,
              relation_name: :posts,
              foreign_key: :category_id,
              association_foreign_key: :post_id,
            }
          },
        },
        toots: {
          columns: [
            :id,
            :body,
            :tooted_at,
          ],
          factory: toot_factory,
          belongs_to: {
            tooter: {
              relation_name: :users,
              foreign_key: :tooter_id,
            },
          },
        },
      }
    }


    # This hash represents the data structure that will be written to
    # the database.
    let(:fixture_tables_hash) {
      {
        users: [
          user_1_data,
          user_2_data,
          user_3_data,
        ],
        posts: [
          post_1_data,
          post_2_data,
        ],
        comments: [
          comment_1_data,
          comment_2_data,
        ],
        categories: [
          category_1_data,
          category_2_data,
        ],
        categories_to_posts: [
          {
            post_id: post_1_data.fetch(:id),
            category_id: category_1_data.fetch(:id),
          },
          {
            post_id: post_1_data.fetch(:id),
            category_id: category_2_data.fetch(:id),
          },
          {
            post_id: post_2_data.fetch(:id),
            category_id: category_2_data.fetch(:id),
          },
        ],
        toots: [
          # Toot ordering is inconsistent for scope testing.
          toot_2_data,
          toot_1_data,
          toot_3_data,
        ],
      }
    }

    let(:user_1_data) {
      {
        id: "user/1",
        first_name: "Stephen",
        last_name: "Best",
        email: "bestie@gmail.com",
      }
    }

    let(:user_2_data) {
      {
        id: "user/2",
        first_name: "Hansel",
        last_name: "Trickett",
        email: "hansel@gmail.com",
      }
    }

    let(:user_3_data) {
      {
        id: "user/3",
        first_name: "Jasper",
        last_name: "Trickett",
        email: "jasper@gmail.com",
      }
    }

    let(:post_1_data) {
      {
        id: "post/1",
        author_id: "user/1",
        subject: "Object mapping",
        body: "It is often tricky",
      }
    }

    let(:post_2_data) {
      {
        id: "post/2",
        author_id: "user/1",
        subject: "Object mapping part 2",
        body: "Lazy load all the things!",
      }
    }

    let(:comment_1_data) {
      {
        id: "comment/1",
        post_id: "post/1",
        commenter_id: "user/2",
        body: "Trololol",
      }
    }

    let(:comment_2_data) {
      {
        id: "comment/2",
        post_id: "post/1",
        commenter_id: "user/1",
        body: "You are so LOL",
      }
    }

    let(:category_1_data) {
      {
        id: "category/1",
        name: "good",
      }
    }

    let(:category_2_data) {
      {
        id: "category/2",
        name: "bad",
      }
    }

    let(:category_3_data) {
      {
        id: "category/3",
        name: "ugly",
      }
    }

    let(:toot_1_data) {
      {
        id: "toot/1",
        tooter_id: "user/1",
        body: "Armistice toots",
        tooted_at: Time.parse("2014-11-11 11:11:00 UTC").iso8601,
      }
    }
    let(:toot_2_data) {
      {
        id: "toot/2",
        tooter_id: "user/1",
        body: "Tooting every second",
        tooted_at: Time.parse("2014-11-11 11:11:01 UTC").iso8601,
      }
    }

    let(:toot_3_data) {
      {
        id: "toot/3",
        tooter_id: "user/1",
        body: "Join me in a minutes' toots",
        tooted_at: Time.parse("2014-11-11 11:11:02 UTC").iso8601,
      }
    }
  end
end