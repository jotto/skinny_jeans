require 'time'
require 'benchmark'
require 'rubygems'
require 'sqlite3'
require 'active_record'
require 'zlib'
require 'fileutils'
require 'uri'
require 'cgi'
require File.expand_path(File.dirname(__FILE__) + "/skinny_jeans/skinny_jeans_string_parser")
# require 'home_run'

class SkinnyJeans

  def self.execute(logfile_path, sqlite_db_path, path_regexp, date_regexp)
    self.new(logfile_path, sqlite_db_path, path_regexp, date_regexp).execute
  end

  attr_accessor :hash_of_dates, :hash_of_dates_for_keywords, :last_pageview_at

  def initialize(logfile_path, sqlite_db_path, path_regexp, date_regexp)
    @logfile_path, @sqlite_db_path, @path_regexp, @date_regexp = [logfile_path, sqlite_db_path, path_regexp, date_regexp]
    @is_gzipped = !logfile_path.to_s[/gz/].nil?
    prepare_db
    @hash_of_dates = {}
    @hash_of_dates_for_keywords = {}
    @last_datetime = nil
  end

  class SkinnyJeanDb < ActiveRecord::Base
    self.abstract_class = true
  end

  def prepare_db
    # create database if necessary
    SQLite3::Database.new(@sqlite_db_path)
    SkinnyJeanDb.establish_connection(:adapter => 'sqlite3', :database => @sqlite_db_path)
    # create tables if necessary
    if !Pageview.table_exists?
      SkinnyJeanDb.connection.create_table(:pageviews) do |t|
        t.column :date, :date
        t.column :path, :string
        t.column :pageview_count, :integer
      end
      # flow tight like skinny jeans with these compound indexes
      SkinnyJeanDb.connection.add_index(:pageviews, [:date, :path], :name => "date_path_index")
      SkinnyJeanDb.connection.add_index(:pageviews, [:date, :pageview_count], :name => "date_pageview_count_index")
    end
    if !Update.table_exists?
      SkinnyJeanDb.connection.create_table(:updates) do |t|
        t.column :last_pageview_at, :timestamp
        t.column :lines_parsed, :integer
        t.column :last_line_parsed, :string
      end
    end

    # addition from 2010-12-06 to track search traffic specifically
    if !PageviewKeyword.table_exists?
      SkinnyJeanDb.connection.create_table(:pageview_keywords) do |t|
        t.column :date, :date
        t.column :path, :string
        t.column :pageview_count, :integer
        t.column :keyword, :string
      end
      SkinnyJeanDb.connection.add_index(:pageview_keywords, [:date, :path, :keyword], :name => "date_path_keyword_index")
      # SkinnyJeanDb.connection.add_index(:pageview_keywords, [:date, :pageview_count], :name => "date_pageview_count_index")
    end

  end

  def execute

    lines_parsed = 0
    last_line_parsed, last_pageview_at, lineno_of_last_line_parsed = [nil,nil,nil]
    # last_update = Update.order("id DESC").limit(1).first
    last_update = Update.find(:first, :order => "id DESC", :limit => 1)

    # see if the last_line_parsed parsed exists in the current log file
    # if it doesnt exist, we'll simply read anything with a timestamp greater than last_pageview_at
    if last_update
      last_pageview_at, last_line_parsed = last_update.last_pageview_at, last_update.last_line_parsed
      file_reader do |line, lineno|
        if line.to_s[0..254] == last_line_parsed.to_s[0..254]
          lineno_of_last_line_parsed = lineno
          break
        end
      end
      puts "last line parsed was\n#{last_line_parsed}\nat lineno #{lineno_of_last_line_parsed}"
    end

    realtime = Benchmark.realtime do
      date_path_pairs_array = []
      lineno = -1

      file_reader do |line, index|
        lineno += 1
        next if lineno_of_last_line_parsed && lineno <= lineno_of_last_line_parsed

        path_match = line[@path_regexp, 1]
        next if path_match.nil?
        date_match = line[@date_regexp, 1]
        next if date_match.nil?
        datetime_obj = parse_string_as_date(date_match)

        next if lineno_of_last_line_parsed.nil? && !last_pageview_at.nil? && datetime_obj < last_pageview_at

        insert_or_increment(datetime_obj, path_match, SkinnyJeans::StringParser.extract_search_query(line))
        @last_pageview_at = datetime_obj
        last_line_parsed = line.to_s[0..254] # only 255 characters because we store it in the database
        lines_parsed += 1
      end
    end

    puts "completed parsing in #{realtime}"

    persisted = 0
    persisted_pageview_keywords = 0
    realtime = Benchmark.realtime do

      hash_of_dates.each do |date, hash_of_paths|
        hash_of_paths.keys.each do |path|
          pv = Pageview.find_or_create_by_date_and_path(date, path)
          pv.pageview_count ||= 0
          pv.pageview_count += hash_of_paths[path]
          pv.save!
          persisted += 1
        end
      end

      hash_of_dates_for_keywords.each do |date, hash_of_paths|
        hash_of_paths.keys.each do |path|
          hash_of_paths[path].keys.each do |keyword|
            pvk = PageviewKeyword.find_or_create_by_date_and_path_and_keyword(date, path, keyword)
            pvk.keyword = keyword.to_s[0..254]
            pvk.pageview_count ||= 0
            pvk.pageview_count += hash_of_paths[path][keyword]
            pvk.save!
            persisted_pageview_keywords += 1
          end
        end
      end

    end

    puts "completed persistence in #{realtime}"

    Update.create!({:last_pageview_at => self.last_pageview_at, :lines_parsed => lines_parsed, :last_line_parsed => last_line_parsed.to_s[0..254]})

    puts("total records in DB: #{Pageview.count}
lines parsed this round: #{lines_parsed}
lines persisted this round:#{persisted}
total SkinnyJeans executions since inception: #{Update.count}")

    return self

  end

  # copies the log file, reads it, then removes it
  def file_reader

    temp_file_path = "#{@logfile_path}.copy"
    temp_file = FileUtils.cp(@logfile_path, temp_file_path)

    if @is_gzipped
      lineno = 0
      Zlib::GzipReader.new(File.new(temp_file_path, "r")).each_line{|line|yield([line,lineno]);lineno+=1}
      # Zlib::GzipReader.open(@logfile_path).each_line{|line|yield([line,lineno]);lineno+=1}
    else
      File.new(temp_file_path, "r").each_with_index{|line, lineno| yield([line,lineno])}
    end

    FileUtils.rm_f(temp_file_path)
  end

  def pageview;get_ar_class(Pageview);end
  def update;get_ar_class(Update);end
  def pageview_keyword;get_ar_class(PageviewKeyword);end

  def get_ar_class(klass)
    begin;return(klass);rescue(ActiveRecord::ConnectionNotEstablished);prepare_db;end
  end

  private

  # return a ruby Time object
  def parse_string_as_date(date_string = "02/Oct/2010:11:17:44 -0700")
    day,month,year,hour,minute,seconds,zone = date_string.scan(/(\d{1,2})\/(\w{3,5})\/(\d{4}):(\d\d):(\d\d):(\d\d)\s(-?\d{3,4})/).flatten
    Time.parse("#{year}-#{month}-#{day} #{hour}:#{minute}:#{seconds} #{zone}")
  end

  def insert_or_increment(_datetime_obj, _path, _search_keyword = nil)

    date_string = _datetime_obj.strftime(("%Y-%m-%d"))

    # data for all pageviews
    hash_of_dates[date_string] ||= {}
    hash_of_dates[date_string][_path] ||= 0
    hash_of_dates[date_string][_path] += 1

    return if _search_keyword.nil?

    # data for just pageviews coming from search
    hash_of_dates_for_keywords[date_string] ||= {}
    hash_of_dates_for_keywords[date_string][_path] ||= {}
    hash_of_dates_for_keywords[date_string][_path][_search_keyword] ||= 0
    hash_of_dates_for_keywords[date_string][_path][_search_keyword] += 1

  end

  class Pageview < SkinnyJeanDb
  end
  class PageviewKeyword < SkinnyJeanDb
  end
  class Update < SkinnyJeanDb
  end

end

# SkinnyJeans::execute(ARGV.first) if "#{$0}".gsub(/.*\//,"") == "skinny_jeans.rb"
