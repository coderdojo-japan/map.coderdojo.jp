#!/usr/bin/env ruby
require 'json'

dojos_earth = []
dojos_japan = []

File.open("dojos_earth.json") do |file|
  dojos_earth = JSON.load(file)
end

File.open("dojos_japan.json") do |file|
  dojos_japan = JSON.load(file) #.map{|data| data.transform_keys!(&:to_sym) }
end

name2text = {}
dojos_japan.each do |dojo|
  name2text[dojo['name']] = "<a href='#{dojo['url']}' target='_blank' rel='noopener'>Webサイトを見る</a><br />"
end

features = []
dojos_earth.each do |dojo|
  # 活動していない道場は除外
  #
  # stage:
  # 0: In planning
  # 1: Open, come along
  # 2: Register ahead
  # 3: 満員
  # 4: 活動していません
  if dojo["geoPoint"] && dojo["stage"] != 4
    if dojo['name'] == 'Chofu'
      dojo['name'].gsub!('Chofu', '調布')
    end

    features << {
      "type" => "Feature",
      "geometry" => {
        "type" => "Point",
        "coordinates" => [dojo["geoPoint"]["lon"], dojo["geoPoint"]["lat"]]
      },
      "properties" => {
        "description" => "#{dojo['name']}<br />#{name2text[dojo['name']]}<a target='_blank' href='http://zen.coderdojo.com/dojos/#{dojo['urlSlug']}'>zen</a>"
      }
    }
  end
end

geojson = {
  "type": "FeatureCollection",
  "features": features
}

File.open("dojos.geojson", "w") do |file|
  JSON.dump(geojson, file)
end
