#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

uri     = URI.parse("https://zen.coderdojo.com/api/2.0/dojos")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Accept"]    = "application/json"
request.body = JSON.dump({
  "query" => {
    "verified" => 1,
    "deleted" => 0,
    "fields$" => [
      "name",
      "geo_point",
      "country",
      "stage",
      "url_slug",
      "start_time",
      "end_time",
      "private",
      "frequency",
      "alternative_frequency",
      "day"
    ]
  }
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

DOJOS_DATA = JSON.parse response.body, symbolize_names: true
DOJOS_JSON = JSON.pretty_generate DOJOS_DATA.sort_by{|dojo| dojo[:id]}

File.open("dojos_earth.json", "w") do |file|
  file.write(DOJOS_JSON)
end

# Show next step for developers
puts DOJOS_JSON
puts ''
puts 'Status Code: ' + response.code
puts ''
puts 'Check out JSON data you fetched by:'
puts '$ cat dojos_earth.json'
