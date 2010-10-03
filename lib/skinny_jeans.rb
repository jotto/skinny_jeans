require 'time'
require 'benchmark'
require 'rubygems'
require 'sqlite3'
require 'active_record'
require 'home_run'

class Pageview < ActiveRecord::Base
end
class Update < ActiveRecord::Base
end

class SkinnyJeans
  class << self

    def prepare_db(sqlite_db_path)
      # create database if necessary
      SQLite3::Database.new(sqlite_db_path)
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => sqlite_db_path)
      # create tables if necessary
      if !Pageview.table_exists?
        ActiveRecord::Base.connection.create_table(:pageviews) do |t|
          t.column :date, :date
          t.column :path, :string
          t.column :pageview_count, :integer
        end
        # flow tight like skinny jeans with these compound indexes
        ActiveRecord::Base.connection.add_index(:pageviews, [:date, :path], :name => "date_path_index")
        ActiveRecord::Base.connection.add_index(:pageviews, [:date, :pageview_count], :name => "date_pageview_count_index")
      end
      if !Update.table_exists?
        ActiveRecord::Base.connection.create_table(:updates) do |t|
          t.column :last_pageview_at, :timestamp
          t.column :lines_parsed, :integer
        end
      end
    end

    def execute(logfile_path, sqlite_db_path, path_regexp, date_regexp)

      prepare_db(sqlite_db_path)
      skinny_jean = self.new
      lines_parsed = 0
      last_update = Update.order("id DESC").limit(1).first
      last_pageview_at = last_update ? last_update.last_pageview_at : nil
      realtime = Benchmark.realtime do
        date_path_pairs_array = []

        File.new(logfile_path, "r").each do |line|
          path_match = line[path_regexp,1]
          next if path_match.nil?
          date_match = line[date_regexp,1]
          next if date_match.nil?
          time_object = parse_string_as_date(date_match)
          next if !last_pageview_at.nil? && time_object < last_pageview_at
          skinny_jean.insert_or_increment([time_object,path_match])
          lines_parsed += 1
        end

        skinny_jean.hash_of_dates
      end

      puts "completed parsing in #{realtime}"

      realtime = Benchmark.realtime do
        skinny_jean.hash_of_dates.each do |date, hash_of_paths|
          hash_of_paths.keys.each do |path|
            pv = Pageview.find_or_create_by_date_and_path(date, path)
            pv.pageview_count ||= 0
            pv.pageview_count += hash_of_paths[path]
            pv.save!
          end
        end
      end
      
      puts "completed persistence in #{realtime}"

      Update.create!({:last_pageview_at => skinny_jean.last_pageview_at, :lines_parsed => lines_parsed})

      puts "total records in DB: #{Pageview.count}, total times parsed: #{Update.count}"

    end

    # return a ruby Time object
    def parse_string_as_date(date_string = "02/Oct/2010:11:17:44 -0700")
      day,month,year,hour,minute,seconds,zone = date_string.scan(/(\d{1,2})\/(\w{3,5})\/(\d{4}):(\d\d):(\d\d):(\d\d)\s(-?\d{3,4})/).flatten
      Time.parse("#{year}-#{month}-#{day} #{hour}:#{minute}:#{seconds} #{zone}")
    end

  end

  attr_accessor :hash_of_dates, :last_pageview_at

  def initialize
    @hash_of_dates = {}
    @last_datetime = nil
  end

  def insert_or_increment(date_path_pair)
    datetime, path = date_path_pair
    date = datetime.strftime(("%Y-%m-%d"))
    hash_of_dates[date] ||= {}
    hash_of_dates[date][path] ||= 0
    hash_of_dates[date][path] += 1
    @last_pageview_at = datetime
  end

end

# SkinnyJeans::execute(ARGV.first) if "#{$0}".gsub(/.*\//,"") == "skinny_jeans.rb"
