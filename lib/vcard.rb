# Copyright (C) 2008 Sam Roberts

# This library is free software; you can redistribute it and/or modify
# it under the same terms as the ruby language itself, see the file
# VPIM-LICENSE.txt for details.

require "date"
require "open-uri"
require "stringio"

require "vcard/attachment"
require "vcard/bnf"
require "vcard/dirinfo"
require "vcard/enumerator"
require "vcard/errors"
require "vcard/field"
require "vcard/vcard"

module Vcard
  ONGOING_QP = /ENCODING=QUOTED-PRINTABLE:.*=$/

  # Split on \r\n or \n to get the lines, unfold continued lines (they
  # start with " " or \t), and return the array of unfolded lines.
  #
  # This also supports the (invalid) encoding convention of allowing empty
  # lines to be inserted for readability - it does this by dropping zero-length
  # lines.
  def self.unfold(card) #:nodoc:
      unfolded = []

      prior_line = nil
      card.lines do |line|
        line.chomp!
        # If it's a continuation line, add it to the last.
        # If it's an empty line, drop it from the input.
        if line =~ /^[ \t]/
          unfolded[-1] << line[1, line.size-1]
        elsif prior_line && (prior_line =~ ONGOING_QP)
          # Strip the trailing = off prior line, then append current line
          unfolded[-1] = prior_line[0, prior_line.length-1] + line
        elsif line =~ /^$/
        else
          unfolded << line
        end
        prior_line = unfolded[-1]
      end

      unfolded
  end

  # Convert a +sep+-seperated list of values into an array of values.
  def self.decode_list(value, sep = ",") # :nodoc:
    list = []

    value.split(sep).each do |item|
      item.chomp!(sep)
      list << yield(item)
    end

    list
  end

  # Convert a RFC 2425 date into an array of [year, month, day].
  def self.decode_date(v) # :nodoc:
    raise ::Vcard::InvalidEncodingError, "date not valid (#{v})" unless v =~ Bnf::DATE
    [$1.to_i, $2.to_i, $3.to_i]
  end

  # Convert a RFC 2425 date into a Date object.
  def self.decode_date_to_date(v)
    Date.new(*decode_date(v))
  end

  # Note in the following the RFC2425 allows yyyy-mm-ddThh:mm:ss, but RFC2445
  # does not. I choose to encode to the subset that is valid for both.

  # Encode a Date object as "yyyymmdd".
  def self.encode_date(d) # :nodoc:
     "%0.4d%0.2d%0.2d" % [d.year, d.mon, d.day]
  end

  # Encode a Date object as "yyyymmdd".
  def self.encode_time(d) # :nodoc:
     "%0.4d%0.2d%0.2d" % [d.year, d.mon, d.day]
  end

  # Encode a Time or DateTime object as "yyyymmddThhmmss"
  def self.encode_date_time(d) # :nodoc:
     "%0.4d%0.2d%0.2dT%0.2d%0.2d%0.2d" % [d.year, d.mon, d.day, d.hour, d.min, d.sec]
  end

  # Convert a RFC 2425 time into an array of [hour,min,sec,secfrac,timezone]
  def self.decode_time(v) # :nodoc:
    raise ::Vcard::InvalidEncodingError, "time '#{v}' not valid" unless match = Bnf::TIME.match(v)
    hour, min, sec, secfrac, tz = match.to_a[1..5]

    [hour.to_i, min.to_i, sec.to_i, secfrac ? secfrac.to_f : 0, tz]
  end

  def self.array_datetime_to_time(dtarray) #:nodoc:
  # We get [year, month, day, hour, min, sec, usec, tz]
    tz = (dtarray.pop == "Z") ? :gm : :local
    Time.send(tz, *dtarray)
  rescue ArgumentError => e
    raise ::Vcard::InvalidEncodingError, "#{tz} #{e} (#{dtarray.join(', ')})"
  end

  # Convert a RFC 2425 time into an array of Time objects.
  def self.decode_time_to_time(v) # :nodoc:
    array_datetime_to_time(decode_date_time(v))
  end

  # Convert a RFC 2425 date-time into an array of [year,mon,day,hour,min,sec,secfrac,timezone]
  def self.decode_date_time(v) # :nodoc:
    raise ::Vcard::InvalidEncodingError, "date-time '#{v}' not valid" unless match = Bnf::DATE_TIME.match(v)
    year, month, day, hour, min, sec, secfrac, tz = match.to_a[1..8]

    [
      # date
      year.to_i, month.to_i, day.to_i,
      # time
      hour.to_i, min.to_i, sec.to_i, secfrac ? secfrac.to_f : 0, tz
    ]
  end

  def self.decode_date_time_to_datetime(v) #:nodoc:
    year, month, day, hour, min, sec = decode_date_time(v)
    # TODO - DateTime understands timezones, so we could decode tz and use it.
    DateTime.civil(year, month, day, hour, min, sec, 0)
  end

  # decode_boolean
  #
  # float
  #
  # float_list

  # Convert an RFC2425 INTEGER value into an Integer
  def self.decode_integer(v) # :nodoc:
    raise ::Vcard::InvalidEncodingError, "integer not valid (#{v})" unless v =~ Bnf::INTEGER
    v.to_i
  end

  #
  # integer_list

  # Convert a RFC2425 date-list into an array of dates.
  def self.decode_date_list(v) # :nodoc:
    decode_list(v) do |date|
      date.strip!
      decode_date(date) if date.length > 0
    end.compact
  end

  # Convert a RFC 2425 time-list into an array of times.
  def self.decode_time_list(v) # :nodoc:
    decode_list(v) do |time|
      time.strip!
      decode_time(time) if time.length > 0
    end.compact
  end

  # Convert a RFC 2425 date-time-list into an array of date-times.
  def self.decode_date_time_list(v) # :nodoc:
    decode_list(v) do |datetime|
      datetime.strip!
      decode_date_time(datetime) if datetime.length > 0
    end.compact
  end

  # Convert RFC 2425 text into a String.
  # \\ -> \
  # \n -> NL
  # \N -> NL
  # \, -> ,
  # \; -> ;
  #
  # I've seen double-quote escaped by iCal.app. Hmm. Ok, if you aren't supposed
  # to escape anything but the above, everything else is ambiguous, so I'll
  # just support it.
  def self.decode_text(v) # :nodoc:
    # FIXME - I think this should trim leading and trailing space
    v.gsub(/\\(.)/) do
      case $1
      when "n", "N"
        "\n"
      else
        $1
      end
    end
  end

  def self.encode_text(v) #:nodoc:
    v.to_str.gsub(/[\\,;]/, '\\\\\0').gsub(/\r?\n/, "\\n")
  end

  # v is an Array of String, or just a single String
  def self.encode_text_list(v, sep = ",") #:nodoc:
    v.to_ary.map { |t| encode_text(t) }.join(sep)
  rescue
    encode_text(v)
  end

  # Convert a +sep+-seperated list of TEXT values into an array of values.
  def self.decode_text_list(value, sep = ",") # :nodoc:
    # Need to do in two stages, as best I can find.
    list = value.scan(/([^#{sep}\\]*(?:\\.[^#{sep}\\]*)*)#{sep}/).map { |v| decode_text(v.first) }
    list << $1 if value.match(/([^#{sep}\\]*(?:\\.[^#{sep}\\]*)*)$/)
    list
  end

  # param-value = paramtext / quoted-string
  # paramtext  = *SAFE-CHAR
  # quoted-string      = DQUOTE *QSAFE-CHAR DQUOTE
  def self.encode_paramtext(value)
    if value =~ Bnf::ALL_SAFECHARS
      value
    else
      raise ::Vcard::Unencodable, "paramtext #{value.inspect}"
    end
  end

  def self.encode_paramvalue(value)
    if value =~ Bnf::ALL_SAFECHARS
      value
    elsif value =~ Bnf::ALL_QSAFECHARS
      %Q{"#{value}"}
    else
      raise ::Vcard::Unencodable, "param-value #{value.inspect}"
    end
  end

  # Unfold the lines in +card+, then return an array of one Field object per
  # line.
  def self.decode(card) #:nodoc:
    unfold(card).map { |line| DirectoryInfo::Field.decode(line) }
  end


  # Expand an array of fields into its syntactic entities. Each entity is a sequence
  # of fields where the sequences is delimited by a BEGIN/END field. Since
  # BEGIN/END delimited entities can be nested, we build a tree. Each entry in
  # the array is either a Field or an array of entries (where each entry is
  # either a Field, or an array of entries...).
  def self.expand(src) #:nodoc:
    # output array to expand the src to
    dst = []
    # stack used to track our nesting level, as we see begin/end we start a
    # new/finish the current entity, and push/pop that entity from the stack
    current = [dst]

    for f in src
      if f.name? "BEGIN"
        e = [f]

        current.last.push(e)
        current.push(e)
      elsif f.name? "END"
        current.last.push(f)

        unless current.last.first.value? current.last.last.value
          raise "BEGIN/END mismatch (#{current.last.first.value} != #{current.last.last.value})"
        end

        current.pop
      else
        current.last.push(f)
      end
    end

    dst
  end

  # Split an array into an array of all the fields at the outer level, and
  # an array of all the inner arrays of fields. Return the array [outer,
  # inner].
  def self.outer_inner(fields) #:nodoc:
    # TODO - use Enumerable#partition
    # seperate into the outer-level fields, and the arrays of component
    # fields
    outer = []
    inner = []
    fields.each do |line|
      case line
      when Array then inner << line
      else outer << line
      end
    end
    return outer, inner
  end
end
