# Copyright (C) 2008 Sam Roberts

# This library is free software; you can redistribute it and/or modify
# it under the same terms as the ruby language itself, see the file
# LICENSE-VPIM.txt for details.

module Vcard
  # Contains regular expression strings for the EBNF of RFC 2425.
  module Bnf #:nodoc:

    # 1*(ALPHA / DIGIT / "-")
    # Note: I think I can add A-Z here, and get rid of the "i" matches elsewhere.
    # Note: added "_" to allowed because its produced by Notes  (X-LOTUS-CHILD_UID:)
    # Note: added "/" to allowed because its produced by KAddressBook (X-messaging/xmpp-All:)
    # Note: added " " to allowed because its produced by highrisehq.com (X-GOOGLE TALK:)
    NAME    = "[-a-z0-9_/][-a-z0-9_/ ]*"

    # <"> <Any character except CTLs, DQUOTE> <">
    QSTR    = '"([^"]*)"'

    # *<Any character except CTLs, DQUOTE, ";", ":", ",">
    PTEXT   = '([^";:,]+)'

    # param-value = ptext / quoted-string
    PVALUE  = "(?:#{QSTR}|#{PTEXT})"

    # param = name "=" param-value *("," param-value)
    # Note: v2.1 allows a type or encoding param-value to appear without the type=
    # or the encoding=. This is hideous, but we try and support it, if there
    # is no "=", then $2 will be "", and we will treat it as a v2.1 param.
    PARAM = ";(#{NAME})(=?)((?:#{PVALUE})?(?:,#{PVALUE})*)"

    # V3.0: contentline  =   [group "."]  name *(";" param) ":" value
    # V2.1: contentline  = *( group "." ) name *(";" param) ":" value
    #
    # We accept the V2.1 syntax for backwards compatibility.
    #LINE = "((?:#{NAME}\\.)*)?(#{NAME})([^:]*)\:(.*)"
    LINE = "^((?:#{NAME}\\.)*)?(#{NAME})((?:#{PARAM})*):(.*)$"

    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE = "(\d\d\d\d)-?(\d\d)-?(\d\d)"

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzone = sign time-hour [":"] time-minute
    TIME = "(\d\d):?(\d\d):?(\d\d)(\.\d+)?(Z|[-+]\d\d:?\d\d)?"

    # integer = (["+"] / "-") 1*DIGIT
    INTEGER = "[-+]?\d+"

    # QSAFE-CHAR = WSP / %x21 / %x23-7E / NON-US-ASCII
    #  ; Any character except CTLs and DQUOTE
    QSAFECHAR = "[ \t\x21\x23-\x7e\x80-\xff]"

    # SAFE-CHAR  = WSP / %x21 / %x23-2B / %x2D-39 / %x3C-7E / NON-US-ASCII
    #   ; Any character except CTLs, DQUOTE, ";", ":", ","
    SAFECHAR = "[ \t\x21\x23-\x2b\x2d-\x39\x3c-\x7e\x80-\xff]"
  end
end
