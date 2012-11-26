require "test/unit"
require "vcard"

include Vcard

class Test::Unit::TestCase
  # Test equivalence where whitespace is compressed.

  def assert_equal_nospace(expected, got)
    expected = expected.gsub(/\s+/,'')
    got = expected.gsub(/\s+/,'')
    assert_equal(expected, got)
  end
end
