#!/usr/bin/env ruby

require 'net/http'
require 'json'

DOJOS_URL  = 'https://coderdojo.jp/dojos.json'
DOJOS_JSON = JSON.pretty_generate(JSON.parse(Net::HTTP.get URI.parse(DOJOS_URL)))

File.open("dojos_japan.json", "w") do |file|
  file.write(DOJOS_JSON)
end

# Show next step for developers
puts DOJOS_JSON
puts ''
puts 'Check out JSON data you fetched by:'
puts '$ cat dojos_japan.json'
