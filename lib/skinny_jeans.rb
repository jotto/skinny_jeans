require 'time'
require 'benchmark'
require 'zlib'
require 'fileutils'
require 'uri'
require 'cgi'
require 'rubygems'
require 'active_record'
require 'sqlite3'
require File.expand_path(File.dirname(__FILE__) + "/skinny_jeans/string_parser")
require File.expand_path(File.dirname(__FILE__) + "/skinny_jeans/log_parser")
# require 'home_run'


# SkinnyJeans::execute(ARGV.first) if "#{$0}".gsub(/.*\//,"") == "skinny_jeans.rb"
module SkinnyJeans
  class SkinnyJeanDb < ActiveRecord::Base
    self.abstract_class = true
  end
  class Pageview < SkinnyJeanDb;end
  class PageviewKeyword < SkinnyJeanDb;end
  class Update < SkinnyJeanDb;end

  class << self
    def prepare_db(sqlite_db_path)
      # create database if necessary
      SQLite3::Database.new(sqlite_db_path)
      SkinnyJeanDb.establish_connection(:adapter => 'sqlite3', :database => sqlite_db_path)
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

  end

end

