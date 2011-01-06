# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{skinny_jeans}
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Otto"]
  s.date = %q{2011-01-05}
  s.email = %q{jonathan.otto@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc",
     "TODO"
  ]
  s.files = [
    ".gitignore",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "lib/skinny_jeans.rb",
     "lib/skinny_jeans/log_parser.rb",
     "lib/skinny_jeans/string_parser.rb",
     "skinny_jeans.gemspec"
  ]
  s.homepage = %q{http://github.com/jotto/skinny_jeans}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fast webserver log parser for persisting daily pageviews per path to sqlite}
  s.test_files = [
    "test/skinny_jeans_string_parser_test.rb",
     "test/skinny_jeans_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3-ruby>, [">= 1.2.4"])
      s.add_runtime_dependency(%q<activerecord>, [">= 2.3.8"])
    else
      s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.4"])
      s.add_dependency(%q<activerecord>, [">= 2.3.8"])
    end
  else
    s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.4"])
    s.add_dependency(%q<activerecord>, [">= 2.3.8"])
  end
end

