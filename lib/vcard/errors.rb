# Copyright (C) 2008 Sam Roberts

# This library is free software; you can redistribute it and/or modify
# it under the same terms as the ruby language itself, see the file
# LICENSE-VPIM.txt for details.

module Vcard
  # Exception used to indicate that data being decoded is invalid, the message
  # should describe what is invalid.
  class InvalidEncodingError < StandardError; end

  # Exception used to indicate that data being decoded is unsupported, the message
  # should describe what is unsupported.
  #
  # If its unsupported, its likely because I didn't anticipate it being useful
  # to support this, and it likely it could be supported on request.
  class UnsupportedError < StandardError; end

  # Exception used to indicate that encoding failed, probably because the
  # object would not result in validly encoded data. The message should
  # describe what is unsupported.
  class Unencodeable < StandardError; end
end
