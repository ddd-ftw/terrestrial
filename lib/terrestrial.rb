require "logger"
require "terrestrial/public_conveniencies"

module Terrestrial
  extend PublicConveniencies

  LOGGER = Logger.new(STDERR)

  module AutoValue
    attr_accessor :value

    def __auto_value?
      true
    end

    def sql_literal(_dataset)
      empty? ? "NULL" : value.to_s
    end

    def empty?
      value == NoValue
    end

    private

    NoValue = Module.new
  end

  require "delegate"

  class AutoInteger < DelegateClass(Fixnum)
    include AutoValue

    def initialize(value = NoValue)
      self.value = value
    end

    def value
      __getobj__
    end

    def value=(v)
      __setobj__(v)
    end
  end
end
