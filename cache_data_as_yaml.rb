#!/usr/bin/env ruby
require 'json'
require 'yaml'
require 'fileutils'

# This script caches the Clubs API's data as YAML format.
# Earth data: from RasPi's Clubs API: https://clubs-api.raspberrypi.org
EARTH_YAML_PATH = '_data/earth.yml'

# Ensure _data directory exists
FileUtils.mkdir_p('_data')

# Load Earth data (use string keys, not symbols)
dojos_earth = JSON.load(File.read('dojos_earth.json'),
                   nil,
                   symbolize_names:  false,
                   create_additions: false)

# Save all Earth data as YAML
IO.write(EARTH_YAML_PATH, dojos_earth.to_yaml)
puts "✅ Cached #{dojos_earth.size.to_s.rjust(4)} Earth dojos to #{EARTH_YAML_PATH}"

# Count Japan dojos for information
dojos_japan = dojos_earth.select { |dojo| dojo['countryCode'] == 'JP' }
puts "   (Incl. #{dojos_japan.size.to_s.rjust(4)} Japan's active/inactive dojos)"

puts
puts "Finished caching JSON data as YAML."
puts
