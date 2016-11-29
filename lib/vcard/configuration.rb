module Vcard
  class Configuration

    attr_accessor :raise_on_invalid_line
    alias_method :raise_on_invalid_line?, :raise_on_invalid_line

    attr_accessor :ignore_invalid_vcards
    alias_method :ignore_invalid_vcards?, :ignore_invalid_vcards

    def initialize
      set_default_values
    end

    def reset
      set_default_values
    end

    private

    def set_default_values
      @raise_on_invalid_line = true
      @ignore_invalid_vcards = true
    end

  end
end
