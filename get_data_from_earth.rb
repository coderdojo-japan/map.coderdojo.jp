#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'set'

# Set default number_of_dojos to detect if
# Clubs API has breaking changes in Actions
File.write('tmp/number_of_dojos', 0)

API_URI = URI.parse('https://clubs-api.raspberrypi.org/graphql')
HEADERS = {
  'accept'       => 'application/json',
  'content-type' => 'application/json'
}

ALL_DOJOS_QUERY = <<~GRAPH_QL
  query (
    # No need to filter to fetch all dojo data on earth.
    # $countryCode: String!,
    #
    # This 'after' has which page we have read and the next page to read.
    $after: String,
  ) {
    clubs(
      after: $after,
      first: 400,
      filterBy: {
        # No need to filter to fetch all dojo data on earth.
        # countryCode: $countryCode,
        #
        # For DEBUG add this "JP" filter
        #countryCode: "JP",
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
GRAPH_QL

# This 'variables' is fixed parameter name and cannot be renamed.
# https://graphql.org/learn/queries/#variables
#variables = {
#  # MEMO: No need to filter to fetch all dojo data on earth.
#  # countryCode: 'JP'
#}
JP_DOJOS_QUERY = <<~GRAPH_QL
  query (
    $after: String
  ) {
    clubs(
      after: $after,
      first: 400,
      filterBy: {
        countryCode: "JP",
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
GRAPH_QL

def request_data(query:, variables:)
  request      = Net::HTTP::Post.new(API_URI.request_uri, HEADERS)
  request.body = { query:, variables: }.to_json
  req_options  = { use_ssl: API_URI.scheme == 'https' }

  response = Net::HTTP.start(API_URI.hostname, API_URI.port, req_options) do |http|
    http.request(request)
  end

  # pp JSON.parse(response.body, symbolize_names: true)
  # JSON.parse(response.body, symbolize_names: true)[:data][:clubs]
  response_data = JSON.parse(response.body, symbolize_names: true)
  if response_data[:errors]
    puts "Error: #{response_data[:errors]}"
    return { nodes: [], pageInfo: { endCursor: nil, hasNextPage: false } }
  end

  response_data[:data][:clubs]
end

dojo_data   = []
unique_ids  = Set.new
page_number = 0
print 'Fetching page by page: '

# Fetch clubs for Japan without filtering by brand
variables = { after: nil }
query = JP_DOJOS_QUERY
begin
  print "#{page_number = page_number.succ}.."
  fetched_data = request_data(query: query, variables: variables)
  fetched_data[:nodes].each do |dojo|
    unless unique_ids.include?(dojo[:id])
      dojo_data << dojo
      unique_ids.add(dojo[:id])
    end
  end
  page_info = fetched_data[:pageInfo]
  variables[:after] = page_info[:endCursor]
end while page_info[:hasNextPage]

# Fetch clubs for other countries with filtering by brand
variables = { after: nil }
query = ALL_DOJOS_QUERY
begin
  print "#{page_number = page_number.succ}.."
  fetched_data = request_data(query: query, variables: variables)
  fetched_data[:nodes].each do |dojo|
    unless unique_ids.include?(dojo[:id])
      dojo_data << dojo
      unique_ids.add(dojo[:id])
    end
  end
  page_info = fetched_data[:pageInfo]
  variables[:after] = page_info[:endCursor]
end while page_info[:hasNextPage]

File.write('tmp/number_of_dojos', dojo_data.length)
File.open('dojos_earth.json', 'w') do |file|
  file.puts JSON.pretty_generate(dojo_data.sort_by{|dojo| dojo[:id]})
end

# Show next step for developers
#puts DOJOS_JSON
puts ''
puts 'Fetched number of dojos: ' + File.read('tmp/number_of_dojos')
puts ''
puts 'Check out its details by:'
puts '$ cat dojos_earth.json'
puts ''
