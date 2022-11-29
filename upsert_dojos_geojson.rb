#!/usr/bin/env ruby
require 'json'
require 'active_support/core_ext/hash/keys'

dojos_earth = []
dojos_japan = []

File.open("dojos_earth.json") do |file|
  dojos_earth = JSON.load(file).map{|data| data.deep_transform_keys!(&:to_sym) }
end

File.open("dojos_japan.json") do |file|
  dojos_japan = JSON.load(file).map{|data| data.transform_keys!(&:to_sym) }
end

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

    # 細かな名寄せ for Proof of Concept (PoC)
    dojo[:name].gsub!('Chofu',     '調布')
    dojo[:name].gsub!('Gifu',      '岐阜')
    dojo[:name].gsub!('Eniwa',     '恵庭')
    dojo[:name].gsub!('muroran@kuru', '室蘭')
    dojo[:name].gsub!('SapporoEast',  '札幌東')
    dojo[:name].gsub!('Sapporo',      '札幌')
    dojo[:name].gsub!('Ebetsu, Hokkaido', '江別')
    dojo[:name].gsub!('Nara, Nara',  '奈良')
    dojo[:name].gsub!('Ikoma, Nara', '生駒')
    dojo[:name].gsub!('天白,名古屋,愛知', '天白')
    dojo[:name].gsub!('shikatsu', '師勝')
    dojo[:name].gsub!('Tondabayashi, Osaka', '富田林')
    dojo[:name].gsub!('Osakasayama, Osaka', '大阪狭山')

    dojo[:name].gsub!('富山@長江', '富山')
    dojo[:name].gsub!('Kanazawa, Ishikawa @ HackforPlay', '金沢')

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
