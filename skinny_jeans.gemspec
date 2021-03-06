# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "skinny_jeans"
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Otto"]
  s.date = "2013-02-03"
  s.description = "Fast webserver log parser for persisting daily pageviews per path to sqlite"
  s.email = "jonathan.otto@gmail.com"
  s.extra_rdoc_files = [
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    "README.rdoc",
    "Rakefile",
    "TODO",
    "VERSION",
    "lib/skinny_jeans.rb",
    "lib/skinny_jeans/log_parser.rb",
    "lib/skinny_jeans/string_parser.rb",
    "skinny_jeans.gemspec"
  ]
  s.homepage = "http://github.com/jotto/skinny_jeans"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Fast webserver log parser for persisting daily pageviews per path to sqlite"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3-ruby>, [">= 1.3.3"])
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<spinner>, [">= 1.0.0"])
    else
      s.add_dependency(%q<sqlite3-ruby>, [">= 1.3.3"])
      s.add_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_dependency(%q<spinner>, [">= 1.0.0"])
    end
  else
    s.add_dependency(%q<sqlite3-ruby>, [">= 1.3.3"])
    s.add_dependency(%q<activerecord>, [">= 3.0.0"])
    s.add_dependency(%q<spinner>, [">= 1.0.0"])
  end
end

