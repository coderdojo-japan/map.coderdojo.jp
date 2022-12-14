#!/usr/bin/env ruby
require 'json'

dojos_earth = []
dojos_japan = []
zen2japan   = {}

File.open("dojos_earth.json") do |file|
  dojos_earth = JSON.load(file, nil, symbolize_names: true, create_additions: false)
end

File.open("dojos_japan.json") do |file|
  dojos_japan = JSON.load(file, nil, symbolize_names: true, create_additions: false)
end

# Sample format of dojo2dojo.csv:
# Japan登録名	Zen登録名
# ひばりヶ丘	Hibarigaoka
# ...
File.foreach("dojo2dojo.csv") do |line|
  japan_name, zen_name = line.split("\t").map(&:chomp)
  next if japan_name.empty? or zen_name.empty?
  zen2japan[zen_name] = japan_name
end
#pp zen2japan; p zen2japan.count; p zen2japan['Kunitachi'] ; exit

# Japan's name to text/logo by Hash
name2logo      = {} # => CoderDojo ロゴ
name2site      = {} # => Webサイトを見る
name2is_active = {} # => Active かどうかのフラグ
dojos_japan.each do |dojo|
  # TODO: Ideally want to change marker image into each CoderDojo logo.
  # Details: https://github.com/coderdojo-japan/map.coderdojo.jp/issues/1

  # TODO: Geolonia Maps 側が .webp 画像に対応したら .png への変換などは不要になる (coderdojo.jp からも削除する!)
  name2logo[dojo[:name]] = <<~HTML
    <a href='#{dojo[:url]}' target='_blank' rel='noopener'>
      <img src='#{dojo[:logo].gsub('.webp', '.png')}' alt='#{dojo[:name]}' loading='lazy' width='100px' />
    </a>
  HTML

  name2site[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'>Webサイトを見る</a>"
  name2is_active[dojo[:name]] = dojo[:is_active]
end


features    = []
description = ''
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

      # Skip if not existing or marked as inactive by Japan DB
      next if zen2japan[dojo[:name]].nil?
      next if name2is_active[zen2japan[dojo[:name]]] == false

      # Convert Zen name into Japan name by Hash
      dojo[:name] = zen2japan[dojo[:name]] if zen2japan[dojo[:name]]

      # Count active dojo in Japan displayed on DojoMap for debugging
      japan_count = japan_count.succ
      #p "#{japan_count.to_s.rjust(3, '0')}: #{dojo[:name]}"
    end

    # Compose 'description' passned to Geojson
    if name2logo[dojo[:name]].nil?
      # for Dojos overseas
      description = <<~HTML
        <img src='https://coderdojo.jp/img/dojos/coderdojo.png' alt='CoderDojo logo' width='100px' /><br>
        #{dojo[:name]}<br>
        <a target='_blank' href='http://zen.coderdojo.com/dojos/#{dojo[:urlSlug]}'>連絡先を見る</a>
      HTML
    else
      # for Dojos regeisted in coderdojo.jp
      description = <<~HTML
        #{name2logo[dojo[:name]]}<br>
        #{dojo[:name]}<br>
        #{name2site[dojo[:name]]}<br>
        <a target='_blank' href='http://zen.coderdojo.com/dojos/#{dojo[:urlSlug]}'>連絡先を見る</a>
      HTML
    end

    features << {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [dojo[:geoPoint][:lon], dojo[:geoPoint][:lat]],
      },
      properties: {
        'marker-size'   => 'small', # small, medium, large
        #'marker-color'  => 'rgba(46,154,217, 0.5)',
        'marker-symbol' => 'coderdojo', # MEMO: Set YOUR-API-KEY in index.html to enable this.
        description: description.delete!("\n"),
      }
    }
  end
end

geojson = {
  type: "FeatureCollection",
  features: features
}

DOJOS_GEOJSON = JSON.pretty_generate(geojson)
File.open("dojos.geojson", "w") do |file|
  file.write(DOJOS_GEOJSON)
  #JSON.dump(geojson, file)
end
