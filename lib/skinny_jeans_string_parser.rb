# example
# SkinnyJeansStringParser.extract_search_query("http://search.aol.com/aol/search?enabled_terms=&s_it=comsearch50&q=cool+stuff")
# => "cool stuff"

class SkinnyJeansStringParser

  def self.extract_search_query(_url)
    self.new(_url).get_search_keyword
  end

  attr_accessor :string_value
  def initialize(string_value)
    @string_value = string_value
  end

  # iterate through any URLs we find in a string and return a search query or nil
  def get_search_keyword
    !all_urls.nil? ? all_urls.collect { |_url| extract_search_query_from_url(_url) }[0] : nil
  end

  # pre: some referring URL from google, yahoo, AOL, bing, ask
  # post: whatever the search query was, ASCII or GTFO
  def extract_search_query_from_url(url)
    val = nil
    case url
    when /google\.com/
      val=return_param_from_url(url, "q")
    when /search\.yahoo\.com/
      val=return_param_from_url(url, "p")
    when /search\.aol\.com/
      val=return_param_from_url(url, "q")
    when /ask\.com/
      val=return_param_from_url(url, "q")
    when /bing\.com/
      val=return_param_from_url(url, "q")
    end
    # whitelist of acceptable characters
    val = val.present? && val.gsub(/[^0-9A-Za-z\s"'!@#\$%\^&\*\(\)\?\<\>\[\]:;,\.+-_=]/, '') != val ? nil : val
    return val
  end

  # pre: like http://example.org?q=cool&fun=no, "fun"
  # post: "no"
  def return_param_from_url(url, param_name)
    _uri = URI.parse(URI.encode(url))
    if _uri.query.present?
      _cgi = CGI.parse(_uri.query)
      if _cgi[param_name]
        val = unescape_string(_cgi[param_name].to_s).strip.downcase
        return (!val.nil? && val!='' ? val : nil)
      end
    end
    return nil
  end

  # find all URLs in a string that are at beginning or end of string or are tokenized by spaces
  def all_urls
    @all_urls ||= string_value.split(/\s+/).reject { |_string| !_string.match(/^['"]?https?:['"]?/) }.collect { |url| url.gsub(/["']/,'') }
    @all_urls.empty? ? nil : @all_urls
  end

  private
  def unescape_string(_string)
    temp = _string.dup
    temp = CGI.unescape(temp) while CGI.unescape(temp) != temp
    temp
  end


end