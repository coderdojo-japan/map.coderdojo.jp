#!/usr/bin/env ruby
require 'json'

# Create a minified version of dojos.geojson for production use
geojson = JSON.load(File.read("dojos.geojson"))

# Write minified version (no whitespace)
File.open('dojos.min.geojson', 'w') do |file|
  JSON.dump(geojson, file)
end

# Calculate size reduction
original_size = File.size("dojos.geojson")
minified_size = File.size("dojos.min.geojson")
reduction = ((original_size - minified_size) * 100.0 / original_size).round(1)

puts "✅ Created dojos.min.geojson"
puts "   Original: #{(original_size / 1024.0).round(1)} KB"
puts "   Minified: #{(minified_size / 1024.0).round(1)} KB"
puts "   Reduction: #{reduction}%"
