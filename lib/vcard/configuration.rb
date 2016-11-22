module Vcard
  class Configuration

    attr_accessor :raise_on_invalid_line
    alias_method :raise_on_invalid_line?, :raise_on_invalid_line

    attr_accessor :ignore_invalid_vcards
    alias_method :ignore_invalid_vcards?, :ignore_invalid_vcards

    def initialize
      @raise_on_invalid = true
      @ignore_invalid_vcard = true
    end

  end
end
