#!/usr/bin/env ruby
require 'json'
require 'time'

dojos_earth  = []
dojos_japan  = []
events_japan = []
zen2japan    = {}

json_load_options = { symbolize_names: true, create_additions: false }
File.open("dojos_earth.json") {|file| dojos_earth  = JSON.load(file, nil, json_load_options) }
File.open("dojos_japan.json") {|file| dojos_japan  = JSON.load(file, nil, json_load_options) }
File.open("events_japan.json"){|file| events_japan = JSON.load(file, nil, json_load_options) }
#pp dojos_earth.first, dojos_japan.first, events_japan.first

# dojo2dojo.csv から Dojo 名の突合準備をする
# 【フォーマット】
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
event          = {}
name2event     = {} # => 近日開催イベント
name2logo      = {} # => CoderDojo ロゴ
name2desc      = {} # => CoderDojo 説明文
name2site      = {} # => Webサイトを見る
name2is_active = {} # => Active かどうかのフラグ
dojos_japan.each do |dojo|
  # もし近日開催イベントがあればマーカーに追加する
  if (event = events_japan.find{|e| e[:id] == dojo[:id]})
    date = Time.parse(event[:event_date])
    name2event[dojo[:name]] = "&rarr; 次回: <a href='#{event[:event_url]}' target='_blank' rel='noopener'>#{date.mon}月#{date.day}日</a><br>"
  end

  # TODO: Ideally want to change marker image into each CoderDojo logo.
  # Details: https://github.com/coderdojo-japan/map.coderdojo.jp/issues/1

  # TODO: WebP 画像は外部から読み込めないっぽい? ローカルからなら読み込める
  # 関連: https://github.com/coderdojo-japan/map.coderdojo.jp/pull/8
  name2logo[dojo[:name]] = <<~HTML
    <a href='#{dojo[:url]}' target='_blank' rel='noopener'>
      <img src='/images/dojos/#{dojo[:logo].split('/').last}' alt='#{dojo[:name]}' loading='lazy' width='100px' />
    </a>
  HTML

  name2site[dojo[:name]] = "<a href='#{dojo[:url]}' target='_blank' rel='noopener'>Webサイトを見る</a>"
  name2desc[dojo[:name]] = dojo[:description].size > 10 ?
                           dojo[:description].insert(8, '<br>') :
                           dojo[:description]
  name2is_active[dojo[:name]] = dojo[:is_active]
end


features    = []
description = ''
japan_count = 0
marked_dojos = []
dojos_earth.each do |dojo|
  # 緯度または経度データが無いクラブはスキップ（地図上に配置できないため）
  if dojo[:latitude] && dojo[:longitude]
    #pp dojo

    # 以下の stage ステータスを見て活動中ではない道場は除外
    #
    # stage:              => Clubs API (renewal in 2023/12)
    # 0: In planning      => PENDING
    # 1: Open, come along => OPEN
    # 2: Register ahead   => REGISTER
    # 3: 満員             => FULL
    # 4: 活動していません => ??? (Maybe deleted or PENDING?)
    # Clubs API https://clubs-api.raspberrypi.org/
    #
    # MEMO: Clubs API (旧: Zen API) リニューアル前は下記コードが使えた
    #       if dojo[:geoPoint] && dojo[:country] && dojo[:stage] != 4
    next unless ['OPEN', 'REGISTER', 'FULL'].include? dojo[:stage]

    # アクティブで、地域情報が日本 (JP) の場合、地図上への配置処理に進む
    if dojo[:countryCode] == "JP"

      # dojo2dojo.csv に無かったらスキップ
      # Japan DB 上で Inactive ならスキップ (Clubs DB より厳密に管理されているため)
      next if zen2japan[dojo[:name]].nil?
      next if name2is_active[zen2japan[dojo[:name]]] == false

      # Clubs API 上のクラブ名を Japan DB 上のクラブ前に変換する by Hash
      dojo[:name] = zen2japan[dojo[:name]] if zen2japan[dojo[:name]]

      # デバッグ用: 地図上に配置したクラブ数をコンソールに出力する
      #japan_count = japan_count.succ
      #p "#{japan_count.to_s.rjust(3, '0')}: #{dojo[:name]}"
    end

    # 各マーカー押下時の説明文 ('description') を生成する
    # ロゴ画像がまだ無い場合はデフォルトのロゴで代用
    if name2logo[dojo[:name]].nil?
      # for Dojos overseas
      description = <<~HTML
        <img src='/images/coderdojo.webp' alt='CoderDojo logo' width='100px' /><br>
        #{dojo[:name]}<br>
        <a target='_blank' rel='noopener'
           href='http://zen.coderdojo.com/dojos/#{dojo[:urlSlug]}'>連絡先を見る</a>
      HTML

    # ロゴ画像がある場合はそのまま使用する
    else
      # 複数道場で一括登録している場合は１つのみ地図上に配置する
      # 一括登録例: '西宮・梅田', '藤井寺・柏原', '大田・邑南、他'
      next if marked_dojos.include? dojo[:name]
      marked_dojos << dojo[:name]

      description = <<~HTML
        #{name2logo[dojo[:name]]}<br>
        <b>#{dojo[:name]}</b><br>
        #{name2desc[dojo[:name]]}<br>
        #{name2event[dojo[:name]]}
        #{name2site[dojo[:name]]}
      HTML
    end

    # 地図上に配置するため GeoJSON 形式に変換する
    # https://ja.wikipedia.org/wiki/GeoJSON
    features << {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [dojo[:longitude], dojo[:latitude]],
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
