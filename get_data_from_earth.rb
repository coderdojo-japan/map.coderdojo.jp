#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

## Example script for retrieving all CoderDojos in Japan

API_URI = URI.parse('https://clubs-api.raspberrypi.org/graphql')

HEADERS = {
  'accept'       => 'application/json',
  'content-type' => 'application/json'
}

DOJOS_IN_COUNTRY_QUERY = <<~GRAPHQL
  query (
    # No need to filter to fetch all dojo data on earth.
    # $countryCode: String!,
    #
    # This 'after' has which page we have read and the next page to read.
    $after: String,
  ) {
    clubs(
      after: $after,
      #first: 10,
      filterBy: {
        # No need to filter to fetch all dojo data on earth.
        # countryCode: $countryCode,
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
  # MEMO: No need to filter to fetch all dojo data on earth.
  # countryCode: 'JP'
}

def request_data(variables:)
  request      = Net::HTTP::Post.new(API_URI.request_uri, HEADERS)
  request.body = { query: DOJOS_IN_COUNTRY_QUERY, variables: }.to_json
  req_options  = { use_ssl: API_URI.scheme == 'https' }

  response = Net::HTTP.start(API_URI.hostname, API_URI.port, req_options) do |http|
    http.request(request)
  end
  # pp JSON.parse(response.body, symbolize_names: true)
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

File.open('tmp/number_of_dojos', 'w') { |file| file.write(dojos.length) }

# Show next step for developers
#puts DOJOS_JSON
puts ""
puts "Number of dojos: #{dojos.length}"
puts ""
puts "Check out JSON data you fetched by:"
puts '$ cat dojos_earth.json'
