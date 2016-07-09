require "terrestrial/graph_serializer"
require "terrestrial/graph_loader"
require "terrestrial/short_inspection_string"

module Terrestrial
  class RelationalStore
    include Enumerable
    include ShortInspectionString

    def initialize(mappings:, mapping_name:, datastore:, dataset:, load_pipeline:, dump_pipeline:)
      @mappings = mappings
      @mapping_name = mapping_name
      @datastore = datastore
      @dataset = dataset
      @load_pipeline = load_pipeline
      @dump_pipeline = dump_pipeline
      @eager_data = {}
    end

    attr_reader :mappings, :mapping_name, :datastore, :dataset, :load_pipeline, :dump_pipeline
    private     :mappings, :mapping_name, :datastore, :dataset, :load_pipeline, :dump_pipeline

    def save(graph)
      record_dump = graph_serializer.call(mapping_name, graph)

      dump_pipeline.call(record_dump)

      self
    end

    def all
      self
    end

    def where(*criteria)
      new_with_dataset(dataset.where(*criteria))
    end

    def distinct(*args, &block)
      new_with_dataset(
        dataset.distinct(*args, &block).qualify
      )
    end

    def join(*args, &block)
      new_with_dataset(
        dataset.join(*args, &block).qualify
      )
    end

    def limit(*args, &block)
      new_with_dataset(
        dataset.limit(*args, &block).qualify
      )
    end

    def offset(*args, &block)
      new_with_dataset(
        dataset.offset(*args, &block).qualify
      )
    end

    def subset(name, *params)
      new_with_dataset(
        mapping.subsets.execute(dataset, name, *params)
      )
    end

    def each(&block)
      dataset
        .map { |record|
          graph_loader.call(mapping_name, record, @eager_data)
        }
        .each(&block)
    end

    def eager_load(association_name_map)
      @eager_data = eager_load_associations(mapping, dataset, association_name_map)

      self
    end

    def delete(object, cascade: false)
      dump_pipeline.call(
        graph_serializer.call(mapping_name, object)
          .select { |record| record.depth == 0 }
          .reverse
          .take(1)
          .map { |record|
            DeletedRecord.new(record.namespace, record.identity)
          }
      )
    end

    private

    def mapping
      mappings.fetch(mapping_name)
    end

    def eager_load_associations(mapping, parent_dataset, association_name_map)
      Hash[
        association_name_map.map { |name, deeper_association_names|
          association = mapping.associations.fetch(name)
          association_mapping = mappings.fetch(association.mapping_name)
          association_dataset = get_eager_dataset(association, parent_dataset)

          [
            name,
            {
              superset: association_dataset,
              associations: eager_load_associations(
                association_mapping,
                association_dataset,
                deeper_association_names,
              ),
            }
          ]
        }
      ]
    end

    def get_eager_dataset(association, parent_dataset)
      association.eager_superset(
        association_root_datasets(association),
        parent_dataset,
      )
    end

    def association_root_datasets(association)
      association
        .mapping_names
        .map { |name| mappings.fetch(name) }
        .map(&:namespace)
        .map { |ns| datastore[ns] }
    end

    def new_with_dataset(new_dataset)
      self.class.new(
        dataset: new_dataset,
        mappings: mappings,
        mapping_name: mapping_name,
        datastore: datastore,
        load_pipeline: load_pipeline,
        dump_pipeline: dump_pipeline,
      )
    end

    def graph_serializer
      GraphSerializer.new(mappings: mappings)
    end

    def graph_loader
      GraphLoader.new(
        datasets: datastore,
        mappings: mappings,
        object_load_pipeline: load_pipeline,
      )
    end

    def inspectable_properties
      [
        :mapping_name,
        :dataset,
        :eager_load,
      ]
    end
  end
end
