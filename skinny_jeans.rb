require 'time'
require 'benchmark'
require 'rubygems'
require 'sqlite3'
require 'active_record'

PATH_TO_SQLITE_DB = "/Users/rick_ross/the_bawse/skinny_jeans/sqlite_skinny_jeans.db"

class Pageview < ActiveRecord::Base
end
class Update < ActiveRecord::Base
end

class SkinnyJeans
  class << self

    def prepare_db()
      # create database if necessary
      SQLite3::Database.new(PATH_TO_SQLITE_DB)

      # ACTIVATE
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => PATH_TO_SQLITE_DB)

      # create tables if necessary
      if !Pageview.table_exists?
        ActiveRecord::Base.connection.create_table(:pageviews) do |t|
          t.column :date, :date
          t.column :path, :string
          t.column :pageview_count, :integer
        end

        # flow tight like skinny jeans with these compound index
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


    def execute(filename = ARGV.first)

      prepare_db
      skinny_jean = self.new
      lines_parsed = 0
      last_update = Update.order("id DESC").limit(1).first
      last_pageview_at = last_update ? last_update.last_pageview_at : nil
      realtime = Benchmark.realtime do
        date_path_pairs_array = []

        File.new(filename, "r").each do |line|
          path_match = path_extract_via_regexp(line)
          date_match = date_extract_via_regexp(line)
          next if [path_match, date_match].any?{ |m| m.nil? || m.empty? }
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

    # returns a date string
    def date_extract_via_regexp(string)
      string.scan(/\[(\d.*\d)\]/).flatten.first
    end

    # returns a path string
    def path_extract_via_regexp(string)
      string.scan(/\s\/posts\/(.*)\sHTTP/).flatten.first
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

SkinnyJeans::execute(ARGV.first)