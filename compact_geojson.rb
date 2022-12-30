#!/usr/bin/env ruby
require 'json'

# Just compact it for better loading by Computer
geojson = JSON.load(File.read("dojos.geojson"))
File.open('dojos.geojson', 'w') do |file|
  JSON.dump(geojson, file)
end
