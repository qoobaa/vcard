require "test_helper"

class ConfigurationTest < Test::Unit::TestCase
  def test_should_be_an_instance_of_configuration
    assert Vcard.configuration.is_a?(::Vcard::Configuration)
  end

  def test_have_default_values
    Vcard.configuration.reset
    assert_equal(Vcard.configuration.raise_on_invalid_line, true)
    assert_equal(Vcard.configuration.ignore_invalid_vcards, true)
  end

  def test_allow_configuration_with_block
    Vcard.configuration.reset
    Vcard.configure do |config|
      config.raise_on_invalid_line = false
      config.ignore_invalid_vcards = false
    end
    assert_equal(Vcard.configuration.raise_on_invalid_line, false)
    assert_equal(Vcard.configuration.ignore_invalid_vcards, false)
  end
end