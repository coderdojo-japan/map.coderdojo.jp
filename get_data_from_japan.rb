#!/usr/bin/env ruby

require 'net/http'
require 'json'

BASE_URL    = 'https://coderdojo.jp'
DOJOS_DATA  = JSON.parse Net::HTTP.get(URI.parse "#{BASE_URL}/dojos.json"),  symbolize_names: true
DOJOS_JSON  = JSON.pretty_generate DOJOS_DATA.sort_by{|dojo| dojo[:id]}
EVENTS_DATA = JSON.parse Net::HTTP.get(URI.parse "#{BASE_URL}/events.json"), symbolize_names: true
EVENTS_JSON = JSON.pretty_generate EVENTS_DATA.sort_by{|dojo| dojo[:id]}

File.open("dojos_japan.json", "w") do |file|
  file.write(DOJOS_JSON)
end

File.open("events_japan.json", "w") do |file|
  file.write(EVENTS_JSON)
end

# Show next step for developers
puts DOJOS_JSON
puts ''
puts 'Check out JSON data you fetched by:'
puts '$ cat dojos_japan.json'
puts ''
puts EVENTS_JSON
puts ''
puts 'Check out JSON data you fetched by:'
puts '$ cat events_japan.json'
puts ''
