require "sequel_mapper/association_proxy"

module SequelMapper
  class Graph
    def initialize(datastore:, top_level_namespace:, relation_mappings:)
      @top_level_namespace = top_level_namespace
      @datastore = datastore
      @relation_mappings = relation_mappings
    end

    attr_reader :top_level_namespace, :datastore, :relation_mappings
    private     :top_level_namespace, :datastore, :relation_mappings

    def where(criteria)
      datastore[top_level_namespace]
        .where(criteria)
        .map { |row|
          load(
            relation_mappings.fetch(top_level_namespace),
            row,
          )
        }
    end

    def save(graph_root)
      @persisted_objects = []
      dump(top_level_namespace, graph_root)
    end

    private

    def identity_map
      @identity_map ||= {}
    end

    def dump(relation_name, object)
      return if @persisted_objects.include?(object)
      @persisted_objects.push(object)

      relation = relation_mappings.fetch(relation_name)

      row = object.to_h.select { |field_name, _v|
        relation.fetch(:columns).include?(field_name)
      }

      relation.fetch(:belongs_to, []).each do |assoc_name, assoc_config|
        row[assoc_config.fetch(:foreign_key)] = object.public_send(assoc_name).id
      end

      relation.fetch(:has_many, []).each do |assoc_name, assoc_config|
        object.public_send(assoc_name).each do |assoc_object|
          dump(assoc_config.fetch(:relation_name), assoc_object)
        end

        next unless object.public_send(assoc_name).respond_to?(:removed_nodes)
        object.public_send(assoc_name).removed_nodes.each do |removed_node|
          datastore[assoc_config.fetch(:relation_name)]
            .where(id: removed_node.id)
            .delete
        end
      end

      relation.fetch(:has_many_through, []).each do |assoc_name, assoc_config|
        object.public_send(assoc_name).each do |assoc_object|
          dump(assoc_config.fetch(:relation_name), assoc_object)
        end

        next unless object.public_send(assoc_name).respond_to?(:added_nodes)
        object.public_send(assoc_name).added_nodes.each do |added_node|
          datastore[assoc_config.fetch(:through_relation_name)]
            .insert(
              assoc_config.fetch(:foreign_key) => object.id,
              assoc_config.fetch(:association_foreign_key) => added_node.id,
            )
        end

        object.public_send(assoc_name).removed_nodes.each do |removed_node|
          datastore[assoc_config.fetch(:through_relation_name)]
            .where(assoc_config.fetch(:association_foreign_key) => removed_node.id)
            .delete
        end
      end

      existing = datastore[relation_name]
        .where(id: object.id)

      if existing.empty?
        datastore[relation_name].insert(row)
      else
        existing.update(row)
      end
    end

    def load(relation, row)
      has_many_associations = Hash[
        relation.fetch(:has_many, []).map { |assoc_name, assoc|
         [
            assoc_name,
            AssociationProxy.new(
              datastore[assoc.fetch(:relation_name)]
                .where(assoc.fetch(:foreign_key) => row.fetch(:id))
                .lazy
                .map { |row|
                  load(relation_mappings.fetch(assoc.fetch(:relation_name)), row)
                }
            )
          ]
        }
      ]

      belongs_to_associations = Hash[
        relation.fetch(:belongs_to, []).map { |assoc_name, assoc|
         [
            assoc_name,
            datastore[assoc.fetch(:relation_name)]
              .where(:id => row.fetch(assoc.fetch(:foreign_key)))
              .map { |row|
                load(relation_mappings.fetch(assoc.fetch(:relation_name)), row)
              }
              .fetch(0)
          ]
        }
      ]

      has_many_through_assocations = Hash[
        relation.fetch(:has_many_through, []).map { |assoc_name, assoc|
         [
            assoc_name,
            AssociationProxy.new(
              datastore[assoc.fetch(:relation_name)]
                .where(
                  :id => datastore[assoc.fetch(:through_relation_name)]
                          .where(assoc.fetch(:foreign_key) => row.fetch(:id))
                          .map { |row| row.fetch(assoc.fetch(:association_foreign_key)) }
                )
                .lazy
                .map { |row|
                  load(relation_mappings.fetch(assoc.fetch(:relation_name)), row)
                }
            )
          ]
        }
      ]

      identity_map.fetch(row.fetch(:id)) {
        identity_map.store(
          row.fetch(:id),
          relation.fetch(:factory).call(
            row
              .merge(has_many_associations)
              .merge(has_many_through_assocations)
              .merge(belongs_to_associations)
          )
        )
      }
    end
  end
end