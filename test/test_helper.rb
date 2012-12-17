require "test/unit"
require "vcard"

include Vcard

class Test::Unit::TestCase
  # Test equivalence where whitespace is compressed.

  def assert_equal_nospace(expected, got)
    expected = expected.gsub(/\s+/, "")
    got = expected.gsub(/\s+/, "")
    assert_equal(expected, got)
  end

  def utf_name_test(c)
    card = Vcard::Vcard.decode(c).first
    assert_equal("name", card.name.family)
  rescue => exception
    exception.message << " #{c.inspect}"
    raise
  end

  def be(s)
    s.unpack("U*").pack("n*")
  end

  def le(s)
    s.unpack("U*").pack("v*")
  end

  def vcard(name)
    open("test/fixtures/#{name}.vcard").read
  end

  def vcal(name)
    open("test/fixtures/#{name}.vcal").read
  end
end
