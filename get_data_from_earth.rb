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

graphql_options = {
  # MEMO: No need to filter to fetch all dojo data on earth.
  # countryCode: 'JP'
}

def request_data(graphql_options:)
  request      = Net::HTTP::Post.new(API_URI.request_uri, HEADERS)
  request.body = { query: DOJOS_IN_COUNTRY_QUERY, graphql_options: }.to_json
  req_options  = { use_ssl: API_URI.scheme == 'https' }

  response = Net::HTTP.start(API_URI.hostname, API_URI.port, req_options) do |http|
    http.request(request)
  end
  # pp JSON.parse(response.body, symbolize_names: true)
  JSON.parse(response.body, symbolize_names: true)[:data][:clubs]
end

dojos = []

loop do
  fetched_data = request_data(graphql_options:)

  dojos    += fetched_data[:nodes]
  page_info = fetched_data[:pageInfo]

  break unless page_info[:hasNextPage]

  graphql_options[:after] = page_info[:endCursor]
end

File.write('tmp/number_of_dojos', dojos.length)

# Show next step for developers
#puts DOJOS_JSON
puts ''
puts 'Fetched number of dojos: ' + File.read('tmp/number_of_dojos')
puts ''
puts 'Check out its details by:'
puts '$ cat dojos_earth.json'
puts ''
