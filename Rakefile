begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "Skinny Jeans"
    s.summary = "Fast webserver log parser for persisting daily pageviews per path to sqlite"
    s.email = "jonathan.otto@gmail.com"
    s.homepage = "http://github.com/jotto/skinny-jeans"
    s.authors = ["Jonathan Otto"]
    s.files =  FileList["[A-Z]*"]
    s.add_dependency 'sqlite3-ruby'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end