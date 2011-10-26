require 'rake'
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "skinny_jeans"
    s.summary = "Fast webserver log parser for persisting daily pageviews per path to sqlite"
    s.description = "Fast webserver log parser for persisting daily pageviews per path to sqlite"
    s.email = "jonathan.otto@gmail.com"
    s.homepage = "http://github.com/jotto/skinny_jeans"
    s.authors = ["Jonathan Otto"]
    s.add_dependency 'sqlite3-ruby', '>= 1.3.3'
    s.add_dependency 'activerecord', '>= 3.0.0'
    s.add_dependency 'spinner', '>= 1.0.0'
    # s.add_dependency 'home_run', '>= 1.0.1'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end