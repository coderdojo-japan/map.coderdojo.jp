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

def get_query_from_template(filter)
  query_template = <<~GRAPH_QL
  query (
    # No need to filter to fetch all dojo data on earth like:
    #   $countryCode: String!,
    #   countryCode: $countryCode,
    #
    # This 'after' has which page we have read and the next page to read.
    $after: String,
  ) {
    clubs(
      after: $after,
      first: 400,
      #{filter}
    ) {
      nodes {
        name
        latitude
        longitude
        countryCode
        stage
        urlSlug: url
        id: uuid
        #startTime
        #endTime
        #openToPublic
        #frequency
        #day
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
  GRAPH_QL
end

def request_to_clubs_api(query:, variables:)
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

def fetch_responses_by_request(page_number=0, query:, variables:)
  begin
    print "#{page_number = page_number.succ}.."
    fetched_data = request_to_clubs_api(query: query, variables: variables)
    fetched_data[:nodes].each do |dojo|
      unless @unique_ids.include?(dojo[:id])
        @dojo_data << dojo
        @unique_ids.add(dojo[:id])
      end
    end
    page_info = fetched_data[:pageInfo]
    variables[:after] = page_info[:endCursor]
  end while page_info[:hasNextPage]
end

# Variables to set fetched_data
@dojo_data   = []
@unique_ids  = Set.new

# 日本国内の全クラブ情報を取得する
# CoderDojo Japan API で 'verified' は突合できるため省略
variables    = { after: nil } # Initialize to fetch from start.
filter_by_jp = 'filterBy: { countryCode: "JP" }'
query        = get_query_from_template(filter_by_jp)
print ' JP_DOJOS_QUERY: '


# This 'variables' is fixed parameter name and cannot be renamed.
# https://graphql.org/learn/queries/#variables
#
# variables = {
#   # MEMO: No need to filter to fetch all dojo data on earth.
#   # countryCode: 'JP'
# }
fetch_responses_by_request(query: query, variables: variables)
puts " (JP: #{@dojo_data.count})"

# Fetch clubs for other countries with filtering by brand
variables        = { after: nil }
filter_by_brands = 'filterBy: { brand: CODERDOJO, verified: true }'
query            = get_query_from_template(filter_by_brands)
print 'ALL_DOJOS_QUERY: '
fetch_responses_by_request(query: query, variables: variables)
puts " (Total: #{@dojo_data.count})"

File.write('tmp/number_of_dojos', @dojo_data.length)
File.open('dojos_earth.json', 'w') do |file|
  file.puts JSON.pretty_generate(@dojo_data.sort_by{|dojo| dojo[:id]})
end

# Show next step for developers
#puts DOJOS_JSON
puts ''
puts 'Fetched number of dojos: ' + File.read('tmp/number_of_dojos')
puts ''
puts 'Check out its details by:'
puts '$ cat dojos_earth.json'
puts ''
