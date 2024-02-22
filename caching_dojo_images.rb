#!/usr/bin/env ruby
require 'json'
require 'open-uri'

# Caching images from coderdojo.jp to local filesystem
dojos_japan = []
File.open('dojos_japan.json') do |file|
  dojos_japan = JSON.load(file, nil, symbolize_names: true, create_additions: false)
end

FILEPATH = 'images/dojos'
filename = ''
dojos_japan.each do |dojo|
  filename = dojo[:logo].split('/').last
  next(puts "Skipped: #{filename}") if File.exist? "#{FILEPATH}/#{filename}"

  puts "Try downloading image: " + dojo[:logo]
  URI.open(dojo[:logo]) do |image|
    File.open("#{FILEPATH}/#{filename}", "wb") do |file|
      file.write(image.read)
    end
  end
end
puts "Finished caching images for DojoMap."
puts
