#!/usr/bin/env ruby
require 'json'
require 'active_support/core_ext/hash/keys'

dojos_earth = []
dojos_japan = []
zen2japan   = {}

File.open("dojos_earth.json") do |file|
  dojos_earth = JSON.load(file).map{|data| data.deep_transform_keys!(&:to_sym) }
end

File.open("dojos_japan.json") do |file|
  dojos_japan = JSON.load(file).map{|data| data.transform_keys!(&:to_sym) }
end

File.foreach("dojo2dojo.txt") do |line|
  japan_name, zen_name = line.split("\t").map(&:chomp)
  next if japan_name.empty? or zen_name.empty?
  zen2japan[zen_name] = japan_name
end
#pp zen2japan; p zen2japan.count; p zen2japan['Kunitachi'] ; exit

# Japan's name to text/logo by Hash
name2text = {}
name2logo = {}
dojos_japan.each do |dojo|
  name2text[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'>Webサイトを見る</a><br />"

  # TODO: Image cannot be displayed for some reasone?? (API Restriction??)
  #name2logo[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'><img src='#{dojo[:logo]}' loading='lazy' /></a><br />"
  #p name2logo[dojo[:name]]
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
  if dojo[:geoPoint] && dojo[:stage] != 4

    # Conver name in Zen into name in Japan by Hash
    dojo[:name] = zen2japan[dojo[:name]] if zen2japan[dojo[:name]]

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
