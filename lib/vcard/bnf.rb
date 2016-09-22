# encoding: ascii
# Copyright (C) 2008 Sam Roberts

# This library is free software; you can redistribute it and/or modify
# it under the same terms as the ruby language itself.

module Vcard
  # Contains regular expressions for the EBNF of RFC 2425.
  module Bnf #:nodoc:

    # 1*(ALPHA / DIGIT / "-")
    # Note: "_" allowed because produced by Notes  (X-LOTUS-CHILD_UID:)
    # Note: "/" allowed because produced by KAddressBook (X-messaging/xmpp-All:)
    # Note: " " allowed because produced by highrisehq.com (X-GOOGLE TALK:)
    NAME    = /[\w\/-][ \w\/-]*/

    # <"> <Any character except CTLs, DQUOTE> <">
    QSTR    = /"([^"]*)"/

    # *<Any character except CTLs, DQUOTE, ";", ":", ",">
    PTEXT   = /([^";:,]+)/

    # param-value = ptext / quoted-string
    PVALUE  = /(?:#{QSTR}|#{PTEXT})/

    # param = name "=" param-value *("," param-value)
    # Note: v2.1 allows a type or encoding param-value to appear without the type=
    # or the encoding=. This is hideous, but we try and support it, if there
    # is no "=", then $2 will be "", and we will treat it as a v2.1 param.
    PARAM = /;(#{NAME})(=?)((?:#{PVALUE})?(?:,#{PVALUE})*)/

    # V3.0: contentline  =   [group "."]  name *(";" param) ":" value
    # V2.1: contentline  = *( group "." ) name *(";" param) ":" value
    # We accept the V2.1 syntax for backwards compatibility.
    LINE = /\A((?:#{NAME}\.)*)?(#{NAME})((?:#{PARAM})*):(.*)\z/

    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE_PARTIAL = /(\d\d\d\d)-?(\d\d)-?(\d\d)/
    DATE = /\A\s*#{DATE_PARTIAL}\s*\z/

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzone = sign time-hour [":"] time-minute
    TIME_PARTIAL = /(\d\d):?(\d\d):?(\d\d)(\.\d+)?(Z|[-+]\d\d:?\d\d)?/
    TIME = /\A\s*#{TIME_PARTIAL}\s*\z/

    # date-time = date "T" time
    DATE_TIME = /\A\s*#{DATE_PARTIAL}T#{TIME_PARTIAL}\s*\z/

    # integer = (["+"] / "-") 1*DIGIT
    INTEGER = /\A\s*[-+]?\d+\s*\z/

    # QSAFE-CHAR = WSP / %x21 / %x23-7E / NON-US-ASCII
    #  ; Any character except CTLs and DQUOTE
    # set ascii encoding so that multibyte chars can be properly escaped
    if RUBY_PLATFORM == "java" && RUBY_VERSION < "1.9"
      # JRuby in 1.8 mode doesn't respect the file encoding. See https://github.com/jruby/jruby/issues/1191
      QSAFECHAR = /[ \t\x21\x23-\x7e\x80-\xff]/
    else
      QSAFECHAR = Regexp.new("[ \t\x21\x23-\x7e\x80-\xff]")
    end
    ALL_QSAFECHARS = /\A#{QSAFECHAR}*\z/

    # SAFE-CHAR  = WSP / %x21 / %x23-2B / %x2D-39 / %x3C-7E / NON-US-ASCII
    #   ; Any character except CTLs, DQUOTE, ";", ":", ","
    # escape character classes then create new Regexp
    SAFECHAR = Regexp.new(Regexp.escape("[ \t\x21\x23-\x2b\x2d-\x39\x3c-\x7e\x80-\xff]"))
    ALL_SAFECHARS = /\A#{SAFECHAR}*\z/

    # A quoted-printable encoded string with a trailing '=', indicating that it's not terminated
    UNTERMINATED_QUOTED_PRINTABLE = /ENCODING=QUOTED-PRINTABLE:.*=$/
  end
end
