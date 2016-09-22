require "test_helper"

class VcardTest < Test::Unit::TestCase

  # RFC2425 - 8.1. Example 1
  # Note that this is NOT a valid vCard, it lacks BEGIN/END.
  def test_ex1
    card = nil
    assert_nothing_thrown { card = Vcard::DirectoryInfo.decode(vcard(:ex1)) }
    assert_equal_nospace(vcard(:ex1), card.to_s)

    assert_equal("Babs Jensen", card["cn"])
    assert_equal("Jensen",      card["sn"])

    assert_equal("babs@umich.edu", card[ "email" ])

    assert_equal("+1 313 747-4454", card[ "PhOnE" ])
    assert_equal("1234567890", card[ "x-id" ])
    assert_equal([], card.groups)
  end

  # RFC2425 - 8.2. Example 2
  def test_ex2
    card = nil
    assert_nothing_thrown { card = Vcard::Vcard.decode(vcard(:ex2)).first }
    assert_equal(vcard(:ex2), card.encode(0))
    assert_raises(::Vcard::InvalidEncodingError) { card.version }

    assert_equal("Bj=F8rn Jensen", card.name.fullname)
    assert_equal("Jensen",  card.name.family)
    assert_equal("Bj=F8rn", card.name.given)
    assert_equal("",        card.name.prefix)
    assert_equal('Office Manager;Something Else', card.role)

    assert_equal("Bj=F8rn Jensen", card[ "fn" ])
    assert_equal("+1 313 747-4454", card[ "tEL" ])

    assert_equal(nil, card[ "not-a-field" ])
    assert_equal([], card.groups)

    assert_equal(nil,          card.enum_by_name("n").entries[0].param("encoding"))

    assert_equal(["internet"], card.enum_by_name("Email").entries.first.param("Type"))
    assert_equal(nil,          card.enum_by_name("Email").entries[0].param("foo"))

    assert_equal(["B"],        card.enum_by_name("kEy").to_a.first.param("encoding"))
    assert_equal("B",          card.enum_by_name("kEy").entries[0].encoding)

    assert_equal(["work", "voice", "msg"], card.enum_by_name("tel").entries[0].param("Type"))

    assert_equal([card.fields[6]], card.enum_by_name("tel").entries)

    assert_equal([card.fields[6]], card.enum_by_name("tel").to_a)

    assert_equal(nil, card.enum_by_name("tel").entries.first.encoding)

    assert_equal("B", card.enum_by_name("key").entries.first.encoding)

    assert_equal("dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK", card.enum_by_name("key").entries.first.value_raw)

    assert_equal("this could be \nmy certificate\n", card.enum_by_name("key").entries.first.value)

    card.lines
  end

  # This is my vCard exported from OS X's AddressBook.app.
  def test_ex_apple1
    card = nil
    assert_nothing_thrown { card = Vcard::Vcard.decode(vcard(:ex_apple1)).first }

    assert_equal("Roberts Sam", card.name.fullname)
    assert_equal("Roberts",  card.name.family)
    assert_equal("Sam", card.name.given)
    assert_equal("",        card.name.prefix)
    assert_equal("",        card.name.suffix)

    assert_equal(vcard(:ex_apple1), card.to_s(64))

    assert_equal("3.0", card[ "version" ])
    assert_equal(30,    card.version)

    assert_equal("sroberts@uniserve.com",  card[ "email" ])
    assert_equal(["HOME", "pref"],         card.enum_by_name("email").entries.first.param("type"))
    assert_equal(nil,                      card.enum_by_name("email").entries.first.group)

    assert_equal(["WORK","pref"],  card.enum_by_name("tel").entries[0].param("type"))
    assert_equal(["FAX"],          card.enum_by_name("tel").entries[1].param("type"))
    assert_equal(["HOME"],         card.enum_by_name("tel").entries[2].param("type"))

    assert_equal(nil,              card.enum_by_name("bday").entries[0].param("type"))
    assert_equal(["date"],         card.enum_by_name("bday").entries[0].param("value"))

    assert_equal( 1970,            card.enum_by_name("bday").entries[0].to_time[0].year)
    assert_equal(    7,            card.enum_by_name("bday").entries[0].to_time[0].month)
    assert_equal(   14,            card.enum_by_name("bday").entries[0].to_time[0].day)

    assert_equal("CATEGORIES: Amis/Famille", card[ "note" ])
  end

  def test_nickname
    assert_equal(nil,          Vcard::Vcard.decode(vcard(:nickname0)).first.nickname)
    assert_equal(nil,          Vcard::Vcard.decode(vcard(:nickname1)).first.nickname)
    assert_equal(nil,          Vcard::Vcard.decode(vcard(:nickname2)).first.nickname)
    assert_equal('Big Joey',   Vcard::Vcard.decode(vcard(:nickname3)).first.nickname)
    assert_equal('Big Joey',   Vcard::Vcard.decode(vcard(:nickname4)).first['nickname'])
    assert_equal(['Big Joey', 'Bob'],   Vcard::Vcard.decode(vcard(:nickname5)).first.nicknames)
  end


  # Test data for Vcard.expand
  def test_expand
  ex_expand =<<'EOF'
BEGIN:a
a1:
BEGIN:b
BEGIN:c
c1:
c2:
END:c
V1:
V2:
END:b
a2:
END:a
EOF
    src = Vcard.decode(ex_expand)
    dst = Vcard.expand(src)

    assert_equal('a',   dst[0][0].value)
    assert_equal('A1',  dst[0][1].name)
    assert_equal('b',   dst[0][2][0].value)
    assert_equal('c',   dst[0][2][1][0].value)
    assert_equal('C1',  dst[0][2][1][1].name)
    assert_equal('C2',  dst[0][2][1][2].name)
    assert_equal('c',   dst[0][2][1][3].value)
  end

  # An iCalendar for Vcard.expand
  def test_ical_1
    src = nil
    dst = nil
    assert_nothing_thrown do
      src = Vcard.decode(vcal(:ex_ical_1))
      dst = Vcard.expand(src)
    end
  end

  # Constructed data.
  def _test_cons # FIXME
    card = nil
    assert_nothing_thrown { card = Vcard::Vcard.decode(vcard(:tst1)).first }
    assert_equal(vcard(:tst1), card.to_s)
    assert_equal('Healey\'s\n\nLook up exact time.\n', card[ "description" ])

    # Test the [] API
    assert_equal(nil,         card[ "not-a-field" ])

    assert_equal('firstname', card[ "name" ])

    assert_equal('home@example.com', card[ "email" ])
    assert_equal('home@example.com', card[ "email", "pref" ])
    assert_equal('home@example.com', card[ "email", "internet" ])
    assert_equal('work@example.com', card[ "email", "work" ])


    # Test the merging of vCard 2.1 type fields.
    assert_equal('fax', card[ "fax" ])
    assert_equal('fax', card[ "fax", 'bar' ])
  end

  def test_bad
    # FIXME: this should THROW, it's badly encoded!
    assert_raises(::Vcard::InvalidEncodingError) do
      Vcard::Vcard.decode("BEGIN:VCARD\nVERSION:3.0\nKEYencoding=b:this could be \nmy certificate\n\nEND:VCARD\n")
    end
  end

  def test_create
    card = Vcard::Vcard.create
    key = Vcard::DirectoryInfo.decode("key;type=x509;encoding=B:dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK\n")['key']
    card << Vcard::DirectoryInfo::Field.create('key', key, 'encoding' => :b64)
    assert_equal(key, card['key'])
  end

  def test_decode_date
    assert_equal [2002, 4, 22], Vcard.decode_date(" 20020422  ")
    assert_equal [2002, 4, 22], Vcard.decode_date(" 2002-04-22  ")
    assert_equal [2002, 4, 22], Vcard.decode_date(" 2002-04-22 \n")
  end

  def test_decode_date_list
    assert_equal [[2002, 4, 22]], Vcard.decode_date_list(" 2002-04-22 ")
    assert_equal [[2002, 4, 22],[2002, 4, 22]], Vcard.decode_date_list(" 2002-04-22, 2002-04-22,")
    assert_equal [[2002, 4, 22],[2002, 4, 22]], Vcard.decode_date_list(" 2002-04-22,,, ,   ,2002-04-22, , \n")
    assert_equal [], Vcard.decode_date_list("  ,           , ")
  end

  def test_decode_time
    assert_equal [4, 53, 22, 0, nil], Vcard.decode_time(" 04:53:22 \n")
    assert_equal [4, 53, 22, 0.10, nil], Vcard.decode_time(" 04:53:22.10 \n")
    assert_equal [4, 53, 22, 0.10, "Z"], Vcard.decode_time(" 04:53:22.10Z \n")
    assert_equal [4, 53, 22, 0, "Z"], Vcard.decode_time(" 045322Z \n")
    assert_equal [4, 53, 22, 0, "+0530"], Vcard.decode_time(" 04:5322+0530 \n")
    assert_equal [4, 53, 22, 0.10, "Z"], Vcard.decode_time(" 045322.10Z \n")
  end

  def test_decode_date_time
    assert_equal [2002, 4, 22, 4, 53, 22, 0, nil], Vcard.decode_date_time("20020422T04:53:22 \n")
    assert_equal [2002, 4, 22, 4, 53, 22, 0.10, nil], Vcard.decode_date_time(" 2002-04-22T04:53:22.10 \n")
    assert_equal [2002, 4, 22, 4, 53, 22, 0.10, "Z"], Vcard.decode_date_time(" 20020422T04:53:22.10Z \n")
    assert_equal [2002, 4, 22, 4, 53, 22, 0, "Z"], Vcard.decode_date_time(" 20020422T045322Z \n")
    assert_equal [2002, 4, 22, 4, 53, 22, 0, "+0530"], Vcard.decode_date_time(" 20020422T04:5322+0530 \n")
    assert_equal [2002, 4, 22, 4, 53, 22, 0.10, "Z"], Vcard.decode_date_time(" 20020422T045322.10Z \n")
    assert_equal [2003, 3, 25, 3, 20, 35, 0, "Z"], Vcard.decode_date_time("20030325T032035Z")
  end

  def test_decode_text
    assert_equal "aa,\n\n,\\,\\a;;b", Vcard.decode_text('aa,\\n\\n,\\\\\,\\\\a\;\;b')
  end

  def test_decode_text_list
    assert_equal ['', "1\n2,3", "bbb", '', "zz", ''], Vcard.decode_text_list(',1\\n2\\,3,bbb,,zz,')
  end

  def test_create_1
    card = Vcard::Vcard.create

    card << DirectoryInfo::Field.create('n', 'Roberts;Sam;;;')
    card << DirectoryInfo::Field.create('fn', 'Roberts Sam')
    card << DirectoryInfo::Field.create('email', 'sroberts@uniserve.com', 'type' => ['home', 'pref'])
    card << DirectoryInfo::Field.create('tel', '416 535 5341', 'type' => 'home')
    # TODO - allow the value to be an array, in which case it will be
    # concatentated with ';'
    card << DirectoryInfo::Field.create('adr', ';;376 Westmoreland Ave.;Toronto;ON;M6H 3A6;Canada', 'type' => ['home', 'pref'])
    # TODO - allow the date to be a Date, and for value to be set correctly
    card << DirectoryInfo::Field.create('bday', Date.new(1970, 7, 14), 'value' => 'date')
  end

  def test_birthday
    cards = Vcard::Vcard.decode(vcard(:ex_bdays))

    expected = [
      Date.new(Time.now.year, 12, 15),
      Date.new(2003, 12, 9),
      nil
    ]

    expected.each_with_index { | d, i| assert_equal(d, cards[i].birthday) }
  end

  def test_attach
    card = Vcard::Vcard.decode(vcard(:ex_attach)).first
    card.lines # FIXME - assert values are as expected
  end

  def test_v21_modification
    card0 = Vcard::Vcard.decode(vcard(:ex_21)).first
    card1 = Vcard::Vcard::Maker.make2(card0) do |maker|
      maker.nickname = 'nickname'
    end
    card2 = Vcard::Vcard.decode(card1.encode).first

    assert_equal(card0.version, card1.version)
    assert_equal(card0.version, card2.version)
  end

  def test_v21_versioned_copy
    card0 = Vcard::Vcard.decode(vcard(:ex_21)).first
    card1 = Vcard::Vcard::Maker.make2(Vcard::DirectoryInfo.create([], 'VCARD')) do |maker|
      maker.copy card0
    end
    card2 = Vcard::Vcard.decode(card1.encode).first

    assert_equal(card0.version, card2.version)
  end

  def test_v21_strip_version
    card0 = Vcard::Vcard.decode(vcard(:ex_21)).first

    card0.delete card0.field('VERSION')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')

    assert_raises(ArgumentError) do
      card0.delete card0.field('END')
    end
    assert_raises(ArgumentError) do
      card0.delete card0.field('BEGIN')
    end

    card1 = Vcard::Vcard::Maker.make2(Vcard::DirectoryInfo.create([], 'VCARD')) do |maker|
      maker.copy card0
    end
    card2 = Vcard::Vcard.decode(card1.encode).first

    assert_equal(30,            card2.version)
    assert_equal(nil,           card2.field('TEL'))
  end


  def test_v21_case0
    Vcard::Vcard.decode(vcard(:ex_21_case0)).first
  end

  def test_modify_name
    card = Vcard::Vcard.decode("begin:vcard\nend:vcard\n").first

    assert_raises(::Vcard::Unencodeable) do
      Vcard::Vcard::Maker.make2(card) {}
    end

    card.make do |m|
      m.name {}
    end

    assert_equal('', card.name.given)
    assert_equal('', card.name.fullname)

    assert_raises(TypeError, RuntimeError) do
      card.name.given = 'given'
    end

    card.make do |m|
      m.name do |n|
        n.given = 'given'
      end
    end

    assert_equal('given', card.name.given)
    assert_equal('given', card.name.fullname)
    assert_equal(''     , card.name.family)

    card.make do |m|
      m.name do |n|
        n.family = n.given
        n.prefix = ' Ser '
        n.fullname = 'well given'
      end
    end

    assert_equal('given', card.name.given)
    assert_equal('given', card.name.family)
    assert_equal('Ser given given', card.name.formatted)
    assert_equal('well given', card.name.fullname)
  end

  def test_add_note
    note = "hi\' \  \"\",,;; \n \n field"

    card = Vcard::Vcard::Maker.make2 do |m|
      m.add_note(note)
      m.name {}
    end

    assert_equal(note, card.note)
  end

  def test_empty_tel
    card = Vcard::Vcard.decode(vcard(:empty_tel)).first
    assert_equal(card.telephone, nil)
    assert_equal(card.telephone('HOME'), nil)
    assert_equal([], card.telephones)
  end

  def test_slash_in_field_name
    card = Vcard::Vcard.decode(vcard(:slash_in_field_name)).first
    assert_equal(card.value("X-messaging/xmpp-All"), "some@jabber.id")
    assert_equal(card["X-messaging/xmpp-All"], "some@jabber.id")
  end

  def test_url_decode
    card = Vcard::Vcard.decode(vcard(:url_decode)).first
    assert_equal("www.email.com", card.url.uri)
    assert_equal("www.email.com", card.url.uri.to_s)
    assert_equal("www.email.com", card.urls.first.uri)
    assert_equal("www.work.com", card.urls.last.uri)
  end

  def test_bday_decode
    card = Vcard::Vcard.decode(vcard(:bday_decode)).first

    assert_equal(Date.new(1970, 7, 14), card.birthday)
    assert_equal(1, card.values("bday").size)

    # Nobody should have multiple bdays, I hope, but its allowed syntactically,
    # so test it, along with some variant forms of BDAY
  end

  def test_bday_decode_2
    card = Vcard::Vcard.decode(vcard(:bday_decode_2)).first
    assert_equal(Date.new(1970, 7, 14), card.birthday)
    assert_equal(4, card.values("bday").size)
    assert_equal(Date.new(1970, 7, 14), card.values("bday").first)
    assert_equal(Date.new(Time.now.year, 7, 14), card.values("bday")[1])
    assert_equal(DateTime.new(1970, 7, 15, 3, 45, 12).to_s, card.values("bday")[2].to_s)
    assert_equal(DateTime.new(1970, 7, 15, 3, 45, 12).to_s, card.values("bday").last.to_s)
  end

  def test_bday_decode_3
    card = Vcard::Vcard.decode(vcard(:bday_decode_3)).first

    assert_equal(Date.new(1980, 10, 25), card.birthday)
  end

  # Broken output from Highrise. Report to support@highrisehq.com
  def test_highrises_invalid_google_talk_field
    c = vcard(:highrise)
    card = Vcard::Vcard.decode(c).first
    assert_equal("Doe", card.name.family)
    assert_equal("456 Grandview Building, Wide Street", card.address('work').street)
    assert_equal("123 Sweet Home, Narrow Street", card.address('home').street)
    assert_equal("John Doe & Partners Limited", card.org.first)
    assert_equal("gtalk.john", card.value("x-google talk"))
    assert_equal("http\\://www.homepage.com", card.url.uri)
  end

  def test_gmail_vcard_export
    c = vcard(:gmail)
    card = Vcard::Vcard.decode(c).first
    assert_equal("123 Home, Home Street\r\nKowloon, N/A\r\nHong Kong", card.value("label"))
  end

  def test_title
    title = "She Who Must Be Obeyed"
    card = Vcard::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "Hilda"
        n.family = "Rumpole"
      end
      m.title = title
    end
    assert_equal(title, card.title)
    card = Vcard::Vcard.decode(card.encode).first
    assert_equal(title, card.title)
  end

  def _test_org(*org)
    card = Vcard::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "Hilda"
        n.family = "Rumpole"
      end
      m.org = org
    end
    assert_equal(org, card.org)
    card = Vcard::Vcard.decode(card.encode).first
    assert_equal(org, card.org)
  end

  def test_org_single
    _test_org("Megamix Corp.")
  end

  def test_org_multiple
    _test_org("Megamix Corp.", "Marketing")
  end

  def test_role
    card = Vcard::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "John"
        n.family = "Woe"
      end
      m.add_role "Office Manager\r\n;Something Else"
    end
    assert_equal "Office Manager\n;Something Else", card.role
    assert_match(/Office Manager\\n\\;Something Else/, card.to_s)
    card = Vcard::Vcard.decode(card.encode).first
    assert_equal "Office Manager\n;Something Else", card.role
  end

  def test_note
    card = Vcard::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "John"
        n.family = "Woe"
      end
      m.add_note "line1\r\n;line2"
    end
    assert_equal "line1\n;line2", card.note
    assert_match(/line1\\n\\;line2/, card.to_s)
    card = Vcard::Vcard.decode(card.encode).first
    assert_equal "line1\n;line2", card.note
  end
end
