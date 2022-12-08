#!/usr/bin/env ruby
require 'json'

dojos_earth = []
dojos_japan = []
zen2japan   = {}

# TODO: These data are now updated by hand. Can be improved by automation.
# Details: https://github.com/coderdojo-japan/map.coderdojo.jp/issues/2
File.open("dojos_earth.json") do |file|
  dojos_earth = JSON.load(file, nil, symbolize_names: true, create_additions: false)
end

File.open("dojos_japan.json") do |file|
  dojos_japan = JSON.load(file, nil, symbolize_names: true, create_additions: false)
end

File.foreach("dojo2dojo.txt") do |line|
  japan_name, zen_name = line.split("\t").map(&:chomp)
  next if japan_name.empty? or zen_name.empty?
  zen2japan[zen_name] = japan_name
end
#pp zen2japan; p zen2japan.count; p zen2japan['Kunitachi'] ; exit

# Japan's name to text/logo by Hash
name2text      = {}
name2logo      = {}
name2is_active = {}
dojos_japan.each do |dojo|
  name2text[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'>Webサイトを見る</a><br />"

  # TODO: Image cannot be displayed for some reasone?? (API Restriction??)
  # Details: https://github.com/coderdojo-japan/map.coderdojo.jp/issues/1
  #name2logo[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'><img src='#{dojo[:logo]}' loading='lazy' /></a><br />"
  #p name2logo[dojo[:name]]

  name2is_active[dojo[:name]] = dojo[:is_active]
end


features    = []
japan_count = 0
dojos_earth.each do |dojo|
  # 活動していない道場は除外
  #
  # stage:
  # 0: In planning
  # 1: Open, come along
  # 2: Register ahead
  # 3: 満員
  # 4: 活動していません
  if dojo[:geoPoint] && dojo[:country] && dojo[:stage] != 4

    # Show only active dojos in Japan area on DojoMap
    if dojo[:country][:countryName] == "Japan"

      # Skip if not existing or marked at Inactive by Japan DB
      next if zen2japan[dojo[:name]].nil?
      next if name2is_active[zen2japan[dojo[:name]]] == false

      # Conver name in Zen into name in Japan by Hash
      dojo[:name] = zen2japan[dojo[:name]] if zen2japan[dojo[:name]]

      # Count active dojo in Japan displayed on DojoMap
      japan_count = japan_count.succ
      p "#{japan_count.to_s.rjust(3, '0')}: #{dojo[:name]}"
    end

    features << {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [dojo[:geoPoint][:lon], dojo[:geoPoint][:lat]],
      },
      properties: {
        'marker-size'  => 'medium',
        'marker-color' => 'rgba(46,154,217, 0.5)',
        description: "#{name2logo[dojo[:name]]}#{dojo[:name]}<br />#{name2text[dojo[:name]]}<a target='_blank' href='http://zen.coderdojo.com/dojos/#{dojo[:urlSlug]}'>連絡先を見る</a>",
      }
    }
  end
end

geojson = {
  type: "FeatureCollection",
  features: features
}

File.open("dojos.geojson", "w") do |file|
  JSON.dump(geojson, file)
end
