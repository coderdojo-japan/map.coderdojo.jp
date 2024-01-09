#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

## Example script for retrieving all CoderDojos in Japan

API_URI = URI.parse('https://clubs-api.raspberrypi.org/graphql')

HEADERS = {
  'accept' => 'application/json',
  'content-type' => 'application/json'
}

DOJOS_IN_COUNTRY_QUERY = <<~GRAPHQL
  query (
    $countryCode: String!,
    $after: String,
  ) {
    clubs(
      after: $after,
      filterBy: {
        countryCode: $countryCode,
        brand: CODERDOJO,
        verified: true
      }
    ) {
      nodes {
        name
        latitude
        longitude
        countryCode
        stage
        urlSlug: url
        startTime
        endTime
        openToPublic
        frequency
        day
        id: uuid
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
GRAPHQL

variables = {
 countryCode: 'JP'
}

def request_data(variables:)
  req_options = {
    use_ssl: API_URI.scheme == 'https'
  }
  request      = Net::HTTP::Post.new(API_URI.request_uri, HEADERS)
  request.body = { query: DOJOS_IN_COUNTRY_QUERY, variables: }.to_json

  response = Net::HTTP.start(API_URI.hostname, API_URI.port, req_options) do |http|
    http.request(request)
  end

  JSON.parse(response.body, symbolize_names: true)[:data][:clubs]
end

dojos = []

loop do
 fetched_data = request_data(variables:)

 dojos    += fetched_data[:nodes]
 page_info = fetched_data[:pageInfo]

 break unless page_info[:hasNextPage]

 variables[:after] = page_info[:endCursor]
end

File.open('dojos_earth.json', 'w') do |file|
 file.puts(JSON.pretty_generate(dojos))
end

puts "\nNumber of dojos: #{dojos.length}"
puts "\nCheck out JSON data you fetched by:"
puts '$ cat dojos_data.json'

exit

################

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
