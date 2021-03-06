require "sequel"

module Terrestrial
  module SequelTestSupport
    module_function def build_datastore(_schema)
      db_connection.tap { |db|
        # This test is using the database so we better clean it out first
        truncate_tables

        # The query_counter will let us make assertions about how efficiently
        # the database is being used
        reset_query_counter
        db.loggers << query_counter
      }
    end

    module_function def query_counter
      @@query_counter ||= QueryCounter.new
    end

    module_function def before_suite(schema)
      drop_tables
      create_tables(schema.fetch(:tables))
      add_foreign_keys(schema.fetch(:foreign_keys))
    end

    module_function def excluded_adapters
      "memory"
    end

    module_function def reset_query_counter
      @@query_counter = nil
    end

    module_function def create_database
      `psql postgres --command "CREATE DATABASE $PGDATABASE;"`
    end

    module_function def drop_database
      `psql postgres --command "DROP DATABASE $PGDATABASE;"`
    end

    module_function def drop_tables(tables = db_connection.tables)
      tables.each do |table_name|
        db_connection.drop_table(table_name, cascade: true)
      end
    end

    module_function def truncate_tables(tables = db_connection.tables)
      tables.each do |table_name|
        db_connection[table_name].truncate(cascade: true)
      end
    end

    module_function def db_connection
      @@db_connection ||= Sequel.postgres(
        host: ENV.fetch("PGHOST"),
        user: ENV.fetch("PGUSER"),
        database: ENV.fetch("PGDATABASE"),
      ).tap { Sequel.default_timezone = :utc }
    end

    module_function def create_tables(tables)
      tables.each do |table_name, fields|
        db_connection.create_table(table_name) do
          fields.each do |field|
            type = field.fetch(:type)
            name = field.fetch(:name)
            options = field.fetch(:options, {})

            column(name, type, options)
          end
        end
      end

      tables.keys
    end

    module_function def add_foreign_keys(foreign_keys)
      foreign_keys.each do |(table, fk_col, foreign_table, key_col)|
        db_connection.alter_table(table) do
          add_foreign_key([fk_col], foreign_table, key: key_col, deferrable: false, on_delete: :set_null)
        end
      end
    end

    class QueryCounter
      def initialize
        reset
      end

      def read_count
        read_count_with_describes -
          list_tables_query_count -
          describe_table_queries_count
      end

      def delete_count
        @info.count { |query|
          /\A\([0-9\.]+s\) DELETE/i === query
        }
      end

      def read_count_with_describes
        @info.count { |query|
          /\A\([0-9\.]+s\) SELECT/i === query
        }
      end

      def write_count
        insert_count + update_count
      end

      def update_count
        updates.count
      end

      def insert_count
        inserts.count
      end

      def updates
        @info
          .map { |query| query.gsub(/\A\([0-9\.]+s\) /, "") }
          .select { |query| query.start_with?("UPDATE") }
      end

      def inserts
        @info
          .map { |query| query.gsub(/\A\([0-9\.]+s\) /, "") }
          .select { |query| query.start_with?("INSERT") }
      end

      def show_queries
        puts @info.join("\n")
      end

      def info(message)
        @info.push(message)
      end

      def error(message)
        @error.push(message)
      end

      def warn(message)
        @warn.push(message)
      end

      def reset
        @described_table_queries = []
        @info = []
        @error = []
        @warn = []
      end

      private

      def list_tables_query_count
        @info.count { |query| list_tables_query_pattern.match(query) }
      end

      def describe_table_queries_count
        describe_table_queries.count
      end

      def describe_table_queries
        # TODO this could probably be better solved with finite automata
        described_table_queries = []

        queries_without_table_list
          .take_while { |query|
            described_table_queries.push(query)
            described_table_query_pattern.match(query) &&
              described_table_queries.length == described_table_queries.uniq.length
          }
      end

      def queries_without_table_list
        @info
          .drop_while { |query|
            !list_tables_query_pattern.match(query)
          }
          .drop_while { |query|
            list_tables_query_pattern.match(query)
          }
      end


      def list_tables_query_pattern
        /\A\([0-9\.]+s\) SELECT "relname" FROM "pg_class"/
      end

      def described_table_query_pattern
        /\A\([0-9\.]+s\) SELECT \* FROM "[^"]+" LIMIT 1/i
      end
    end
  end
end
