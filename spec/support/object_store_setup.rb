require "terrestrial"
require "terrestrial/relational_store"
require "terrestrial/relation_mapping"
require "terrestrial/lazy_collection"
require "terrestrial/collection_mutability_proxy"
require "terrestrial/lazy_object_proxy"
require "terrestrial/dataset"
require "terrestrial/query_order"
require "terrestrial/one_to_many_association"
require "terrestrial/many_to_one_association"
require "terrestrial/many_to_many_association"
require "terrestrial/subset_queries_proxy"
require "support/object_graph_setup"

RSpec.shared_context "object store setup" do
  include_context "object graph setup"

  let(:object_store) {
    Terrestrial.object_store(mappings: mappings, datastore: datastore)
  }

  let(:user_store) { object_store[:users] }

  let(:mappings) { Terrestrial.convert_primitive_config(configs) }

  let(:has_many_proxy_factory) {
    ->(query:, loader:, mapping_name:) {
      Terrestrial::CollectionMutabilityProxy.new(
        Terrestrial::LazyCollection.new(
          query,
          loader,
          mappings.fetch(mapping_name).subsets,
        )
      )
    }
  }

  let(:many_to_one_proxy_factory) {
    ->(query:, loader:, preloaded_data:) {
      Terrestrial::LazyObjectProxy.new(
        ->{ loader.call(query.first) },
        preloaded_data,
      )
    }
  }

  let(:configs) {
    {
      users: {
        namespace: :users,
        primary_key: [:id],
        fields: [
          :id,
          :first_name,
          :last_name,
          :email,
        ],
        factory: User.method(:new),
        serializer: :default,
        associations: {
          posts: {
            type: :one_to_many,
            mapping_name: :posts,
            foreign_key: :author_id,
            key: :id,
            proxy_factory: has_many_proxy_factory,
          }
        },
      },

      posts: {
        namespace: :posts,
        primary_key: [:id],
        fields: [
          :id,
          :subject,
          :body,
          :created_at,
        ],
        factory: Post.method(:new),
        serializer: :default,
        associations: {
          comments: {
            type: :one_to_many,
            mapping_name: :comments,
            foreign_key: :post_id,
            key: :id,
            proxy_factory: has_many_proxy_factory,
          },
          categories: {
            type: :many_to_many,
            mapping_name: :categories,
            key: :id,
            foreign_key: :post_id,
            association_foreign_key: :category_id,
            association_key: :id,
            join_mapping_name: :categories_to_posts,
            proxy_factory: has_many_proxy_factory,
          },
        },
      },

      comments: {
        namespace: :comments,
        primary_key: [:id],
        fields: [
          :id,
          :body,
        ],
        factory: Comment.method(:new),
        serializer: :default,
        associations: {
          commenter: {
            type: :many_to_one,
            mapping_name: :users,
            key: :id,
            foreign_key: :commenter_id,
            proxy_factory: many_to_one_proxy_factory,
          },
        },
      },

      categories: {
        namespace: :categories,
        primary_key: [:id],
        fields: [
          :id,
          :name,
        ],
        factory: Category.method(:new),
        serializer: :default,
        associations: {
          posts: {
            type: :many_to_many,
            mapping_name: :posts,
            key: :id,
            foreign_key: :category_id,
            association_foreign_key: :post_id,
            association_key: :id,
            join_mapping_name: :categories_to_posts,
            proxy_factory: has_many_proxy_factory,
          },
        },
      },

      categories_to_posts: {
        namespace: :categories_to_posts,
        primary_key: [:category_id, :post_id],
        fields: [],
        serializer: :null,
        associations: {},
      }
    }
  }
end
