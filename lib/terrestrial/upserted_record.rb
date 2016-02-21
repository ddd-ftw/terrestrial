require "terrestrial/abstract_record"

module Terrestrial
  class UpsertedRecord < AbstractRecord
    def if_upsert(&block)
      block.call(self)
      self
    end

    def insertable
      to_h.reject { |k, v| identity_fields.include?(k) && (v.nil? || empty_auto_value?(v)) }
    end

    def set_auto_id(new_id)
      identity.values
        .select(&method(:empty_auto_value?))
        .each { |v| v.value = new_id }
    end

    protected

    def empty_auto_value?(v)
      v.respond_to?(:__auto_value?) && v.__auto_value? && v.empty?
    end

    def operation
      :upsert
    end
  end
end
