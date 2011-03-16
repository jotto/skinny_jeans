# example
# SkinnyJeans::StringParser.extract_search_query("http://search.aol.com/aol/search?enabled_terms=&s_it=comsearch50&q=cool+stuff")
# => "cool stuff"

module SkinnyJeans
  class StringParser

    class << self
      def extract_search_query(_url)
        self.new(_url).get_search_keyword
      end

      # pre: some referring URL from google, yahoo, AOL, bing, ask
      # post: whatever the search query was, ASCII or GTFO
      def extract_search_query_from_valid_url(url)
        val = nil
        case url
        when /google\.com/
          val=return_param_from_valid_url_or_path(url,"q")
        when /search\.yahoo\.com/
          val=return_param_from_valid_url_or_path(url,"p")
        when /search\.aol\.com/
          val=return_param_from_valid_url_or_path(url,"q")
        when /ask\.com/
          val=return_param_from_valid_url_or_path(url,"q")
        when /bing\.com/
          val=return_param_from_valid_url_or_path(url,"q")
        when /search\-results\.com/
          val=return_param_from_valid_url_or_path(url,"q")
        end
        # whitelist of acceptable characters
        val = !!val && val.gsub(/[^0-9A-Za-z\s"'!@#\$%\^&\*\(\)\?\<\>\[\]:;,\.+-_=]/, '') != val ? nil : val
        return val
      end

      # pre: like http://example.org?q=cool&fun=no, "fun"
      # post: "no"
      def return_param_from_valid_url_or_path(url_or_path, param_name)
        _uri = URI.parse(URI.encode(url_or_path))
        if _uri.query.present?
          _cgi = CGI.parse(_uri.query)
          if _cgi[param_name]
            val = URI.decode(_cgi[param_name].join).strip.downcase
            return (!val.nil? && val!='' ? val : nil)
          end
        end
        return nil
      end

    end

    attr_accessor :string_value
    def initialize(string_value)
      @string_value = string_value
    end

    # find all URLs in a string that are at beginning or end of string or are tokenized by spaces
    def all_urls
      # tokenize a string by space
        # find strings starting with http with optional enclosing quotes
        # remove those quotes from any matches
      @all_urls ||= string_value.split(/\s+/).reject { |_string| !_string.match(/^['"]?https?:['"]?/) }.collect { |url| url.gsub(/\A["']/,'') }.collect { |url| url.gsub(/["']\z/,'') }
      @all_urls.empty? ? nil : @all_urls
    end

    # iterate through any URLs we find in a string and return a search query or nil
    def get_search_keyword
      !all_urls.nil? ? all_urls.collect { |_url| self.class.extract_search_query_from_valid_url(_url) }[0] : nil
    end

  end
end