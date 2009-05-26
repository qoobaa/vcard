# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vcard}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jakub Kuźma"]
  s.date = %q{2009-05-26}
  s.email = %q{qoobaa@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/vcard.rb",
     "lib/vcard/attachment.rb",
     "lib/vcard/dirinfo.rb",
     "lib/vcard/enumerator.rb",
     "lib/vcard/field.rb",
     "lib/vcard/rfc2425.rb",
     "lib/vcard/vcard.rb",
     "test/field_test.rb",
     "test/test_helper.rb",
     "test/vcard_test.rb",
     "vcard.gemspec"
  ]
  s.homepage = %q{http://github.com/qoobaa/vcard}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Vcard support extracted from Vpim (Ruby 1.9.1 compatible)}
  s.test_files = [
    "test/field_test.rb",
     "test/test_helper.rb",
     "test/vcard_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
