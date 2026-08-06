#!/usr/bin/env ruby
require 'json'
require 'time'
require 'yaml'

# マーカーの描画方式を _config.yml の `marker` 設定で切り替える。
#   'default'   => circle マーカー（marker-color）。Geolonia スプライト サーバに
#                  依存せず、障害(502)時もマーカーが消えない。堅牢なため既定値。
#   'coderdojo' => marker-symbol: 'coderdojo'。CoderDojo ロゴを表示できるが、
#                  Geolonia アカウントのカスタム スプライトに 'coderdojo' 画像が
#                  必要で、スプライト サーバ障害時はマーカーが全滅する。
# 背景: 2026/06 に 'coderdojo' がスプライト サーバ 502 で読めずマーカー全滅した。
#       詳細は tests/markers_integrity_test.rb 参照。
#
# 各モードの GeoJSON を常に生成し、テストページ /default.html /coderdojo.html で
# モード別にプレビューできるようにする（本番 index.html は marker_mode を使用）。
MARKER_PROPS = {
  'default'   => { 'marker-color'  => '#2e9ad9' }, # CoderDojo blue (rgb 46,154,217)
  'coderdojo' => { 'marker-symbol' => 'coderdojo' },
}.freeze

config      = File.exist?('_config.yml') ? (YAML.load_file('_config.yml') || {}) : {}
marker_mode = config['marker'].to_s.empty? ? 'default' : config['marker'].to_s
marker_mode = 'default' unless MARKER_PROPS.key?(marker_mode)

dojos_earth  = []
dojos_japan  = []
events_japan = []
zen2japan    = {}

json_load_options = { symbolize_names: true, create_additions: false }
File.open("_data/dojos_earth.json") {|file| dojos_earth  = JSON.load(file, nil, json_load_options) }
File.open("_data/dojos_japan.json") {|file| dojos_japan  = JSON.load(file, nil, json_load_options) }
File.open("_data/events_japan.json"){|file| events_japan = JSON.load(file, nil, json_load_options) }
#pp dojos_earth.first, dojos_japan.first, events_japan.first

# dojo2dojo.csv で Clubs DB と Japan DB のクラブ名を突合する
# 【フォーマット】
# Japan登録名	Zen登録名
# ひばりヶ丘	Hibarigaoka
# ...
# 突合の主役は global_club_id (UUID) に移した。CSV は UUID を持てない Dojo の
# 救済としてだけ残している。詳細は下の「Clubs DB と Japan DB の突合」を参照
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



# == Clubs DB と Japan DB の突合 ==============================================
#
# クラブ ID (UUID) で突き合わせる。Japan DB 側は /dojos.json の global_club_id。
# 以前は dojo2dojo.csv でクラブ名を突合していたが、次の問題があった。
#
#   - 新しい Dojo を追加するたび CSV に 1 行足す運用が必要で、実際に漏れていた
#   - Clubs 側で改名されると追従できない（例: 那覇は「CoderDojo Japan
#     Association (Official Regional Body)」に変わっていて名前が一致しなかった）
#   - 同名クラブが二重登録されていると、先に現れた方を拾ってしまう（流山・古河）
#
# CSV は「まだ global_club_id を持てない Dojo」の救済としてだけ残す。
# 現在は連名道場 2 件（西宮・梅田、大田・邑南、他）が該当する。1 エントリが
# 複数のクラブを表すため、単一の UUID では表せない。
#
# 関連: https://github.com/coderdojo-japan/coderdojo.jp/issues/1616

# 地図に置けるクラブか（座標があり、活動中または準備中）
placeable = ->(club) {
  club[:latitude] && club[:longitude] &&
    ['PLANNING', 'RUNNING_SESSIONS'].include?(club[:status])
}

uuid2japan = dojos_japan.each_with_object({}) { |d, h| h[d[:global_club_id]] = d if d[:global_club_id] }
name2japan = dojos_japan.each_with_object({}) { |d, h| h[d[:name]] = d }
jp_clubs   = dojos_earth.select { |c| c[:countryCode] == 'JP' && placeable.call(c) }

# 1 巡目: UUID で引けるものを確定させる
club2japan = {}
jp_clubs.each do |club|
  d = uuid2japan[club[:id]]
  next if d.nil? || d[:is_active] == false
  club2japan[club[:id]] = { name: d[:name], via: 'uuid' }
end

# 2 巡目: UUID 経路で載らなかった Dojo だけ、CSV の名前突合で救済する。
#
# 判定は「その Dojo が UUID を持つか」ではなく「UUID 経路で実際に載ったか」で行う。
# 前者だと、Clubs 側でクラブが消えたり UUID が変わったりした時に、CSV に行が
# あっても救済されず地図から静かに消える。Clubs 側には同名クラブの二重登録が
# 実在し（流山・古河）、どちらが整理されるかはこちらでは決められない。
placed_names = club2japan.values.map { |v| v[:name] }
jp_clubs.each do |club|
  next if club2japan.key?(club[:id])

  japan_name = zen2japan[club[:name]]
  next if japan_name.nil?
  next if placed_names.include?(japan_name)  # UUID 経路で既に載っている

  d = name2japan[japan_name]
  next if d.nil? || d[:is_active] == false

  placed_names << japan_name
  club2japan[club[:id]] = { name: japan_name, via: 'csv' }
end

features    = []
description = ''
japan_count = 0
japan_dojos = []
marked_dojos = []
dojos_earth.each do |dojo|
  # 緯度または経度データが無いクラブはスキップ（地図上に配置できないため）
  if dojo[:latitude] && dojo[:longitude]
    #pp dojo

    # NOTE: 2025/03/29 に Clubs API は予告なく破壊的な変更がされた
    # https://github.com/coderdojo-japan/map.coderdojo.jp/pull/19

    # 以下の status ステータスを見て活動中ではない道場は除外
    #
    # status:             => Clubs API (as of 2025/03/29)
    # 0: In planning      => PLANNING         (formerly PENDING)
    # 1: Open, come along => RUNNING_SESSIONS (formerly OPEN)
    # 2: Register ahead   => RUNNING_SESSIONS (formerly REGISTER)
    # 3: 満員             => RUNNING_SESSIONS (formerly FULL)
    # 4: 活動していません => ??? (Maybe deleted or PENDING?)
    # Clubs API https://clubs-api.raspberrypi.org/
    # ChatGPT Log: https://chatgpt.com/share/67ecfb6a-26f4-800a-9c79-c3c54d91e829
    #
    # MEMO: Clubs API (旧: Zen API) リニューアル前は下記コードが使えた
    #       if dojo[:geoPoint] && dojo[:country] && dojo[:status] != 4
    next unless ['PLANNING', 'RUNNING_SESSIONS'].include? dojo[:status]

    # アクティブで、地域情報が日本 (JP) の場合、地図上への配置処理に進む
    if dojo[:countryCode] == "JP"

      # 突合できなかったクラブはスキップ（上の「Clubs DB と Japan DB の突合」を参照）。
      # Japan DB 上で Inactive なものも、その中で既に除外している
      next if club2japan[dojo[:id]].nil?

      # Clubs API 上のクラブ名を Japan DB 上のクラブ名に変換する
      dojo[:name_earth] = dojo[:name]
      dojo[:name] = club2japan[dojo[:id]][:name]

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

    # 名寄せ用に ID と日本語名を控える
    japan_dojos << {
      global_club_id: dojo[:id],
      name_japan:     dojo[:name],
      name_earth:     dojo[:name_earth],
      countryCode:    dojo[:countryCode],
      urlSlug:        dojo[:urlSlug],
      status:         dojo[:status],
      matched_by:     club2japan[dojo[:id]][:via],
     } if dojo[:countryCode] == "JP"

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
        # marker-color / marker-symbol はモード別に書き出し時に付与する（下部参照）
        description: description.delete!("\n"),
      }
    }
  end
end

# 指定モードのマーカー属性を付与した FeatureCollection を組み立てる。
# プロパティ順序は marker-size → マーカー属性 → description を維持する。
def build_geojson(features, mode)
  feats = features.map do |f|
    base  = f[:properties]
    props = { 'marker-size' => base['marker-size'] }
            .merge(MARKER_PROPS.fetch(mode))
            .merge(description: base[:description])
    f.merge(properties: props)
  end
  { type: "FeatureCollection", features: feats }
end

# 本番用 dojos.geojson は _config.yml の選択モードで書き出す
IO.write "dojos.geojson", JSON.pretty_generate(build_geojson(features, marker_mode))

# モード別 dojos.#{mode}.geojson も生成（テストページ /#{mode}.html 用）
MARKER_PROPS.each_key do |mode|
  IO.write "dojos.#{mode}.geojson", JSON.pretty_generate(build_geojson(features, mode))
end

IO.write "_data/dojo2dojo.json", JSON.pretty_generate(japan_dojos)

# 突合できなかった active な Dojo を理由付きで書き出す。
#
# 日次の GitHub Actions が生成してそのままデプロイするため、ここが静かに増えても
# 誰も気づかない。ワークフローがこのファイルを見て Slack に通知する。
#
# uuid_not_in_clubs だけが要対応。Japan 側は UUID を持っているのに Clubs 側に
# そのクラブが無い状態で、削除・UUID 変更のいずれかが起きている。
# no_uuid_no_csv は新しい Dojo を追加した直後にも起きるので、異常ではない。
placed_japan_names = club2japan.values.map { |v| v[:name] }
earth_ids          = dojos_earth.map { |c| c[:id] }
unmatched = dojos_japan.select { |d| d[:is_active] && !placed_japan_names.include?(d[:name]) }
                       .map do |d|
  reason = if d[:global_club_id].nil?       then 'no_uuid_no_csv'
           elsif !earth_ids.include?(d[:global_club_id]) then 'uuid_not_in_clubs'
           else 'club_excluded_by_status_or_coordinates'
           end
  { id: d[:id], name: d[:name], global_club_id: d[:global_club_id], reason: reason }
end

Dir.mkdir('tmp') unless Dir.exist?('tmp')
IO.write "tmp/unmatched_dojos.json", JSON.pretty_generate(unmatched)

via = japan_dojos.group_by { |d| d[:matched_by] }.transform_values(&:size)
puts "DojoMap: 日本のマーカー #{japan_dojos.size} 件 (UUID 突合 #{via['uuid'].to_i} / CSV 救済 #{via['csv'].to_i})"
puts "DojoMap: 地図に載らなかった active な Dojo #{unmatched.size} 件"
unmatched.each { |d| puts "  - #{d[:name]} (id=#{d[:id]}): #{d[:reason]}" }

