require "test_helper"

class FieldTest < Test::Unit::TestCase

  Field = Vcard::DirectoryInfo::Field

  def test_encode_decode_text()
    enc_in = "+\\\\+\\n+\\N+\\,+\\;+\\a+\\b+\\c+"
    dec = Vcard.decode_text(enc_in)
    #puts("<#{enc_in}> => <#{dec}>")
    assert_equal("+\\+\n+\n+,+;+a+b+c+", dec)
    enc_out = Vcard.encode_text(dec)
    should_be = "+\\\\+\\n+\\n+\\,+\\;+a+b+c+"
    # Note a, b, and c are allowed to be escaped, but shouldn't be and
    # aren't in output
    #puts("<#{dec}> => <#{enc_out}>")
    assert_equal(should_be, enc_out)

  end

  def test_field4
    line = "t;e=a,b: 4 "
    part = Field.decode0(line)
    assert_equal("4", part[ 4 ])
  end

  def test_field3
    line = "t;e=a,b:4"
    part = Field.decode0(line)
    assert_equal("4", part[ 4 ])
    assert_equal( {"E" => [ "a","b" ] }, part[ 3 ])
  end

  def test_field2
    line = "tel;type=work,voice,msg:+1 313 747-4454"
    part = Field.decode0(line)
    assert_equal("+1 313 747-4454", part[ 4 ])
    assert_equal( {"TYPE" => [ "work","voice","msg" ] }, part[ 3 ])
  end

  def test_field1
    line = 'ORGANIZER;CN="xxxx, xxxx [SC100:370:EXCH]":MAILTO:xxxx@americasm01.nt.com'
    parts = Field.decode0(line)

    assert_equal(nil, parts[1])
    assert_equal("ORGANIZER", parts[2])
    assert_equal({ "CN" => [ "xxxx, xxxx [SC100:370:EXCH]" ] }, parts[3])
    assert_equal("MAILTO:xxxx@americasm01.nt.com", parts[4])
  end

=begin this can not be done :-(
  def test_case_equiv
    line = 'ORGANIZER;CN="xxxx, xxxx [SC100:370:EXCH]":MAILTO:xxxx@americasm01.nt.com'
    field = Field.decode(line)
    assert_equal(true, field.name?('organIZER'))
    assert_equal(true, field === 'organIZER')

    b = nil
    case field
    when 'organIZER'
      b = true
    end

    assert_equal(true, b)
  end
=end

  def test_field0
    assert_equal("name:", line = Field.encode0(nil, "name"))
    assert_equal([ true, nil, "NAME", {}, ""], Field.decode0(line))

    assert_equal("name:value", line = Field.encode0(nil, "name", {}, "value"))
    assert_equal([ true, nil, "NAME", {}, "value"], Field.decode0(line))

    assert_equal("name;encoding=B:dmFsdWU=", line = Field.encode0(nil, "name", { "encoding"=>:b64 }, "value"))
    assert_equal([ true, nil, "NAME", { "ENCODING"=>["B"]}, ["value"].pack("m").chomp ], Field.decode0(line))

    line = Field.encode0("group", "name", {}, "value")
    assert_equal "group.name:value", line
    assert_equal [ true, "GROUP", "NAME", {}, "value"], Field.decode0(line)
  end

  def test_invalid_fields_wih_raise_error
    Vcard::configuration.raise_on_invalid_line = true
    [
      "g.:",
      ":v",
    ].each do |line|
      assert_raises(::Vcard::InvalidEncodingError) { Field.decode0(line) }
    end
  end

  def test_invalid_fields_wihout_raise_error
    Vcard.configuration.raise_on_invalid_line = false
    [
        "g.:",
        ":v",
    ].each do |line|
      assert_nothing_raised { Field.decode0(line) }
    end
  end

  def test_date_encode
    assert_equal("DTSTART:20040101\n", Field.create("DTSTART",  Date.new(2004, 1, 1) ).to_s)
    assert_equal("DTSTART:20040101\n", Field.create("DTSTART", [Date.new(2004, 1, 1)]).to_s)
  end

  def test_field_modify
    f = Field.create("name")


    assert_equal("", f.value)
    f.value = ""
    assert_equal("", f.value)
    f.value = "z"
    assert_equal("z", f.value)

    f.group = "z.b"
    assert_equal("Z.B", f.group)
    assert_equal("z.b.NAME:z\n", f.encode)

    f.value = :group
    assert_equal("Z.B.NAME:group\n", f.encode)
    f.value = "z"

    assert_equal("Z.B", f.group)

    assert_equal("Z.B.NAME:z\n", f.encode)

    f.group = :group
    assert_equal("group.NAME:z\n", f.encode)
    f.group = "z.b"

    assert_equal("z.b.NAME:z\n", f.encode)
    assert_equal("Z.B", f.group)

    f["p0"] = "hi julie"

    assert_equal("Z.B.NAME;P0=hi julie:z\n", f.encode)
    assert_equal(["hi julie"], f.param("p0"))
    assert_equal(["hi julie"], f["p0"])
    assert_equal("NAME", f.name)
    assert_equal("Z.B", f.group)

    # FAIL   assert_raises(ArgumentError) { f.group = "z.b:" }

    assert_equal("Z.B", f.group)

    f.value = "some text"

    assert_equal("some text", f.value)
    assert_equal("some text", f.value_raw)

    f["encoding"] = :b64

    assert_equal("some text", f.value)
    assert_equal([ "some text" ].pack("m*").chomp, f.value_raw)
  end

  def test_field_wrapping
    assert_equal("0:x\n",             Vcard::DirectoryInfo::Field.create("0", "x" * 1).encode(4))
    assert_equal("0:xx\n",            Vcard::DirectoryInfo::Field.create("0", "x" * 2).encode(4))
    assert_equal("0:xx\n x\n",        Vcard::DirectoryInfo::Field.create("0", "x" * 3).encode(4))
    assert_equal("0:xx\n xx\n",       Vcard::DirectoryInfo::Field.create("0", "x" * 4).encode(4))
    assert_equal("0:xx\n xxx\n x\n",  Vcard::DirectoryInfo::Field.create("0", "x" * 6).encode(4))
    assert_equal("0:xx\n xxx\n xx\n", Vcard::DirectoryInfo::Field.create("0", "x" * 7).encode(4))
    assert_equal("0:xxxxxxx\n",       Vcard::DirectoryInfo::Field.create("0", "x" * 7).encode(0))
    assert_equal("0:xxxxxxx\n",       Vcard::DirectoryInfo::Field.create("0", "x" * 7).encode())
    assert_equal("0:#{"x" * 73}\n #{"x" * 74}\n #{"x" * 53}\n", Vcard::DirectoryInfo::Field.create("0", "x" * 200).encode())
  end
end

