require 'time'
require 'benchmark'
require 'zlib'
require 'fileutils'
require 'uri'
require 'cgi'
require 'rubygems'
require 'active_record'
require 'sqlite3'
require 'spinner'

# faster URI decoding (neglible savings)
# leaving comment for reference
# require 'escape_utils'

require File.expand_path(File.dirname(__FILE__) + "/skinny_jeans/string_parser")
require File.expand_path(File.dirname(__FILE__) + "/skinny_jeans/log_parser")

# faster date parsing (about a 17% speed boost)
require 'home_run'


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

# class CGI
#   # @@accept_charset="UTF-8" unless defined?(@@accept_charset)
#   # # URL-encode a string.
#   # #   url_encoded_string = CGI::escape("'Stop!' said Fred")
#   # #      # => "%27Stop%21%27+said+Fred"
#   # def CGI::escape(string)
#   #   string.gsub(/([^ a-zA-Z0-9_.-]+)/) do
#   #     '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
#   #   end.tr(' ', '+')
#   # end
# 
# 
#   # URL-decode a string with encoding(optional).
#   #   string = CGI::unescape("%27Stop%21%27+said+Fred")
#   #      # => "'Stop!' said Fred"
#   def CGI::unescape(string,encoding=@@accept_charset)
#     str=string.tr('+', ' ').force_encoding(Encoding::ASCII_8BIT).gsub(/((?:%[0-9a-fA-F]{2})+)/u) do
#       [$1.delete('%')].pack('H*')
#     end.force_encoding(encoding)
#     str.valid_encoding? ? str : str.force_encoding(string.encoding)
#   end
# end