#!/usr/bin/env ruby
# frozen_string_literal: true

# 地図にマーカーが表示されなくなる回帰を防ぐためのテスト。
#
# 関連 PR: https://github.com/coderdojo-japan/map.coderdojo.jp/pull/28
#
# == 不具合の経緯（2026/06）==
# 「地図にマーカーが表示されない」不具合が発生。GeoJSON 破損を疑ったが、
# dojos.geojson は 1310 件すべて妥当な FeatureCollection / Point だった。
#
# == 実測した真因（ブラウザ コンソール ログ + Geolonia ソース）==
#   Image "coderdojo" could not be loaded.
#   GET https://api.geolonia.com/v1/sprites/basic-v1@2x.json net::ERR_FAILED 502
#
# Geolonia embed は GeoJSON の各ポイントを simplestyle で描画する
# (geolonia/embed src/lib/simplestyle.ts):
#   - marker-symbol あり => symbol レイヤー（icon-image=['get','marker-symbol']）
#                           ※ Geolonia スプライト サーバ依存
#   - marker-symbol なし => circle レイヤー ※ スプライト不要
# 我々は全件 marker-symbol="coderdojo" を使っていたが、'coderdojo' は標準
# スプライト basic-v1 に無いカスタム シンボルで、かつスプライト サーバが 502。
# 結果、マーカー画像が読めず 1 件も描画されなかった。
#
# （補足: data-custom-marker / #custom-marker は「地図中心の単一マーカー」専用で
#   data-marker="on" の時のみ有効。GeoJSON のマーカーには一切作用しない。
#   geolonia/embed src/lib/geolonia-map.ts で確認済み。）
#
# == 恒久対応 ==
# _config.yml の `marker` でマーカー方式を切替可能にした (upsert_dojos_geojson.rb):
#   default   => marker-color による circle マーカー（スプライト非依存・堅牢・既定）
#   coderdojo => marker-symbol: coderdojo（ロゴ表示・スプライト サーバ依存）
#
# == このテストが守る不変条件 ==
#   1. GeoJSON が妥当（FeatureCollection / Point / 座標が範囲内）
#   2. 生成された GeoJSON が _config.yml の marker 設定と一致
#   3. default モードのマーカーはスプライト非依存（marker-symbol を含まない）
#      = Geolonia スプライト サーバ障害(502)でもマーカーが消えない
#
# 実行: bundle exec rake test_markers  (または ruby tests/markers_integrity_test.rb)

require 'minitest/autorun'
require 'json'
require 'yaml'

ROOT         = File.expand_path('..', __dir__)
GEOJSON_PATH = File.join(ROOT, 'dojos.geojson')
CONFIG_PATH  = File.join(ROOT, '_config.yml')

def load_geojson
  JSON.parse(File.read(GEOJSON_PATH))
end

def marker_mode
  config = File.exist?(CONFIG_PATH) ? (YAML.load_file(CONFIG_PATH) || {}) : {}
  mode = config['marker'].to_s
  mode.empty? ? 'default' : mode
end

class GeoJSONIntegrityTest < Minitest::Test
  def setup
    skip "#{GEOJSON_PATH} が存在しません（先に rake upsert_dojos_geojson を実行）" unless File.exist?(GEOJSON_PATH)
    @data = load_geojson
  end

  def test_is_a_feature_collection
    assert_equal 'FeatureCollection', @data['type'], 'GeoJSON のトップレベル type が FeatureCollection ではありません'
  end

  def test_has_at_least_one_feature
    features = @data['features']
    assert_kind_of Array, features, 'features が配列ではありません'
    refute_empty features, 'features が空です（マーカーが 0 件になります）'
  end

  def test_every_feature_has_valid_point_coordinates
    invalid = @data['features'].reject do |f|
      geom   = f['geometry']
      coords = geom && geom['coordinates']
      geom && geom['type'] == 'Point' &&
        coords.is_a?(Array) && coords.size == 2 &&
        coords.all? { |n| n.is_a?(Numeric) } &&
        coords[0].between?(-180, 180) && # 経度
        coords[1].between?(-90, 90)      # 緯度
    end

    assert_empty invalid,
                 "不正な座標を持つフィーチャーが #{invalid.size} 件あります: " \
                 "#{invalid.first(3).map { |f| f.dig('geometry', 'coordinates') }.inspect}"
  end
end

# 真因（スプライト依存マーカーの全滅）を検出するテスト
class MarkerRenderingTest < Minitest::Test
  def setup
    skip "#{GEOJSON_PATH} が存在しません" unless File.exist?(GEOJSON_PATH)
    @features = load_geojson['features']
  end

  # 生成済み GeoJSON が _config.yml の marker 設定と一致しているか
  # （ビルド漏れ・設定と実体の乖離を検出）
  def test_geojson_matches_config_marker_mode
    with_symbol = @features.count { |f| f.dig('properties', 'marker-symbol') }
    with_color  = @features.count { |f| f.dig('properties', 'marker-color') }

    if marker_mode == 'coderdojo'
      assert_equal @features.size, with_symbol,
                   "marker: coderdojo なのに marker-symbol を持つフィーチャーが #{with_symbol}/#{@features.size} 件しかありません。" \
                   'rake upsert_dojos_geojson で再生成してください。'
    else
      assert_equal @features.size, with_color,
                   "marker: default なのに marker-color を持つフィーチャーが #{with_color}/#{@features.size} 件しかありません。" \
                   'rake upsert_dojos_geojson で再生成してください。'
    end
  end

  # default モードではスプライト非依存（marker-symbol を含まない）であること。
  # marker-symbol は Geolonia スプライト サーバに依存し、障害(502)時にマーカーが
  # 全滅する（2026/06 の不具合の真因）。本番は既定でこの安全なモードで出荷する。
  def test_default_mode_is_sprite_independent
    skip "marker: coderdojo はスプライト依存モード（意図的に選択中）" if marker_mode == 'coderdojo'

    with_symbol = @features.select { |f| f.dig('properties', 'marker-symbol') }
    assert_empty with_symbol,
                 "default モードなのに marker-symbol を持つフィーチャーが #{with_symbol.size} 件あります。" \
                 'これは Geolonia スプライト サーバ依存となり、502 障害時にマーカーが全滅します。'
  end
end

# テストページ /default.html /coderdojo.html 用のモード別 GeoJSON バリアントを検証する。
# これらは _config.yml の設定に依らず常に生成される（ビルド成果物なので gitignore 済み）。
class MarkerVariantTest < Minitest::Test
  # モード => そのモードで全フィーチャーが持つべきマーカー属性
  VARIANT_MARKER_KEY = {
    'default'   => 'marker-color',
    'coderdojo' => 'marker-symbol',
  }.freeze

  def test_each_variant_geojson_has_correct_marker_property
    VARIANT_MARKER_KEY.each do |mode, key|
      path = File.join(ROOT, "dojos.#{mode}.geojson")
      skip "dojos.#{mode}.geojson が未生成です（先に rake upsert_dojos_geojson を実行）" unless File.exist?(path)

      features = JSON.parse(File.read(path))['features']
      refute_empty features, "dojos.#{mode}.geojson の features が空です"

      missing = features.reject { |f| f.dig('properties', key) }
      assert_empty missing,
                   "dojos.#{mode}.geojson の #{missing.size} 件が #{key} を持っていません。" \
                   'テストページのマーカーが正しく描画されません。'
    end
  end
end

# ---------------------------------------------------------------------------
# Geolonia 埋め込みスクリプト URL の一元管理テスト
#
# == 経緯（2026/07）==
# Geolonia の旧インフラ（v1）で障害が発生し、世界地図が表示されなくなった。
#   https://github.com/geolonia/docs.geolonia.com/issues/125
# 対処は v1 → v5 への移行だが、当時 URL は 4 つの HTML に計 8 箇所ハードコード
# されており、次のバージョン変更でも同じ多箇所修正が必要な状態だった。
#
# == 恒久対応 ==
# URL を _config.yml の geolonia_embed_url に一元化し、_includes/geolonia_embed.html
# 経由で全ページが参照する。バージョンを上げる時は _config.yml だけ変更すればよい。
#
# このテストは、HTML に URL が再びハードコードされる回帰を防ぐ。
# ---------------------------------------------------------------------------
class GeoloniaEmbedTest < Minitest::Test
  MAP_PAGES = %w[index.html world.html default.html coderdojo.html].freeze

  def setup
    @config = YAML.load_file(File.join(ROOT, '_config.yml'))
  end

  def test_config_has_embed_url
    url = @config['geolonia_embed_url']
    refute_nil url, '_config.yml に geolonia_embed_url が定義されていません。'
    assert_match %r{\Ahttps://cdn\.geolonia\.com/}, url,
                 "geolonia_embed_url が Geolonia の CDN を指していません: #{url}"
  end

  def test_html_pages_do_not_hardcode_embed_url
    offenders = MAP_PAGES.select do |page|
      path = File.join(ROOT, page)
      File.exist?(path) && File.read(path).include?('cdn.geolonia.com')
    end

    assert_empty offenders,
                 "#{offenders.join(', ')} に埋め込み URL がハードコードされています。" \
                 '_config.yml の geolonia_embed_url と _includes/geolonia_embed.html を使ってください。' \
                 'ハードコードするとバージョン変更時に修正漏れが起きます。'
  end

  def test_map_pages_include_the_shared_partial
    missing = MAP_PAGES.reject do |page|
      path = File.join(ROOT, page)
      File.exist?(path) && File.read(path).include?('{% include geolonia_embed.html %}')
    end

    assert_empty missing,
                 "#{missing.join(', ')} が共通パーシャルを読み込んでいません。" \
                 '地図が描画されなくなります。'
  end
end

# ---------------------------------------------------------------------------
# 日本の Dojo が「海外 Dojo 用フォールバック」で描画される回帰を防ぐテスト
#
# == 不具合の経緯（2026/08）==
# CoderDojo鞍手 を追加した直後、地図のポップアップが汎用の CoderDojo ロゴと
# `http://zen.coderdojo.com/dojos/` リンクで表示された。urlSlug が null のため
# リンク先は一覧トップで、その Dojo には辿り着けない状態だった。
#
# == 真因 ==
# upsert_dojos_geojson.rb は `name2logo[dojo[:name]]` が nil のとき海外 Dojo 用の
# フォールバックに落ちる。`name2logo` は _data/dojos_japan.json から作るため、
# Clubs DB には居るが dojos_japan.json にはまだ居ない日本の Dojo が、
# 海外 Dojo として描画されてしまう。
#
# この状態は新規 Dojo を追加した直後に起きる。coderdojo.jp へのデプロイが
# 済むまで、こちらの dojos_japan.json にその Dojo が含まれないため。
#
# == このテストが守る不変条件 ==
#   _data/dojos_japan.json に載っている Dojo（= 日本の Dojo）は、
#   海外 Dojo 用のフォールバックで描画されない。
# ---------------------------------------------------------------------------
require 'tmpdir'
require 'fileutils'

# 海外 Dojo 用フォールバックの目印。
# 独立した 2 つを見る。片方の文言・パスが変わっても、もう片方で検出できる。
FALLBACK_MARK = "/images/coderdojo.webp" # 汎用ロゴ
CONTACT_MARK  = "連絡先を見る"            # 海外 Dojo 用のリンク文言

# 日本の Dojo の登録名。突合の情報源そのものなので、ここから採る
def japan_dojo_names
  JSON.parse(File.read(File.join(ROOT, '_data', 'dojos_japan.json')))
      .filter_map { |d| d['name'] }
end

class JapanDojoFallbackTest < Minitest::Test
  def setup
    skip "#{GEOJSON_PATH} が存在しません" unless File.exist?(GEOJSON_PATH)
  end

  # 日本の Dojo には公式サイトへの「Webサイトを見る」が出る。
  # 海外 Dojo 用の「連絡先を見る」が出ていたら、フォールバックに落ちている。
  # 2026/08 に実際に地図上で見えた症状がこれ。
  def test_no_japan_dojo_shows_the_overseas_contact_link
    japan_names = japan_dojo_names
    features    = load_geojson['features']

    offenders = features.select do |f|
      desc = f.dig('properties', 'description').to_s
      desc.include?(CONTACT_MARK) && japan_names.any? { |n| desc.include?(">#{n}<") }
    end

    assert_empty offenders,
                 "日本の Dojo が #{offenders.size} 件、海外 Dojo 用の「#{CONTACT_MARK}」リンクで" \
                 '描画されています。このリンクは urlSlug を持たないため一覧トップに飛び、' \
                 "その Dojo には辿り着けません: " \
                 "#{offenders.first(3).map { |f| f.dig('properties', 'description').to_s[0, 120] }.inspect}"
  end

  # 出荷される GeoJSON に対する検査。
  # 海外 Dojo がフォールバックで描画されるのは設計どおりなので、
  # Japan DB に載っている日本の Dojo だけを対象にする。
  def test_no_japan_dojo_uses_overseas_fallback
    japan_names = japan_dojo_names
    features    = load_geojson['features']

    offenders = features.select do |f|
      desc = f.dig('properties', 'description').to_s
      desc.include?(FALLBACK_MARK) && japan_names.any? { |n| desc.include?(">#{n}<") }
    end

    assert_empty offenders,
                 "日本の Dojo が #{offenders.size} 件、海外 Dojo 用のフォールバックで描画されています。" \
                 "汎用ロゴと辿り着けない zen.coderdojo.com リンクが表示されます: " \
                 "#{offenders.first(3).map { |f| f.dig('properties', 'description').to_s[0, 120] }.inspect}"
  end
end

# 生成ロジック自体の検査。
# 「Clubs DB には居るが dojos_japan.json には居ない」状況を作って再現させる。
# 出荷済みデータの検査だけでは、データが正しい間はこの欠陥を検出できない。
class JapanDojoFallbackGenerationTest < Minitest::Test
  CLUB = {
    brand:       'CODE_CLUB',
    name:        'CoderDojoテスト町',
    latitude:    33.79,
    longitude:   130.68,
    countryCode: 'JP',
    status:      'RUNNING_SESSIONS',
    urlSlug:     nil,
    id:          '00000000-0000-4000-8000-000000000000',
  }.freeze

  # Clubs DB には居るが Japan DB には居ない = 新規 Dojo を追加した直後の状態。
  # coderdojo.jp へのデプロイが済むまで、この Dojo は dojos_japan.json に載らない
  def test_japan_dojo_missing_from_japan_data_is_not_rendered_as_overseas
    features = generate_features(earth: [CLUB], japan: [])

    fallback = features.select do |f|
      desc = f.dig("properties", "description").to_s
      desc.include?(FALLBACK_MARK) || desc.include?(CONTACT_MARK)
    end

    assert_empty fallback,
                 "日本の Dojo が dojos_japan.json に未反映のとき、海外 Dojo 用のフォールバックで" \
                 "描画されています。汎用ロゴと辿り着けないリンクを出すより、次のデータ更新まで" \
                 "地図に出さない方が安全です。"
  end

  # 上のガードが効きすぎて海外 Dojo まで消す退行を防ぐ。
  # 海外 Dojo は Japan DB に載らないため、フォールバック描画が正しい挙動。
  def test_overseas_dojo_is_still_rendered_with_fallback
    overseas = CLUB.merge(name: 'CoderDojo Test Town', countryCode: 'IE', urlSlug: 'test-town')
    features = generate_features(earth: [overseas], japan: [])

    assert_equal 1, features.size, '海外 Dojo が地図から消えています'
    assert_includes features.first.dig('properties', 'description'), FALLBACK_MARK,
                    '海外 Dojo はフォールバック (汎用ロゴ) で描画されるのが正しい挙動です'
  end

  # Japan DB に載っている日本の Dojo は、自前のロゴとサイトで描画される。
  def test_japan_dojo_in_japan_data_is_rendered_with_its_own_logo
    japan_dojo = {
      id:          1,
      name:        'テスト町',
      url:         'https://example.jp/',
      logo:        'https://coderdojo.jp/img/dojos/test-town.webp',
      description: 'テスト町で毎月開催',
      is_active:   true,
      # Clubs DB との突合は global_club_id (UUID) で行う
      global_club_id: CLUB[:id],
    }
    features = generate_features(earth: [CLUB], japan: [japan_dojo])

    assert_equal 1, features.size, '日本の Dojo が地図から消えています'
    desc = features.first.dig('properties', 'description')
    refute_includes desc, FALLBACK_MARK, '自前のロゴがあるのにフォールバックで描画されています'
    assert_includes desc, 'https://coderdojo.jp/img/dojos/test-town.webp'
    assert_includes desc, 'https://example.jp/'
    refute_includes desc, CONTACT_MARK, "日本の Dojo に海外用の「連絡先を見る」が出ています"
    assert_includes desc, "Webサイトを見る"
  end

  private

  # フィクスチャを一時ディレクトリに置き、生成スクリプトを実行して features を返す
  def generate_features(earth:, japan:)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, '_data'))
      File.write(File.join(dir, '_data/dojos_earth.json'),  JSON.generate(earth))
      File.write(File.join(dir, '_data/dojos_japan.json'),  JSON.generate(japan))
      File.write(File.join(dir, '_data/events_japan.json'), JSON.generate([]))
      File.write(File.join(dir, '_config.yml'), "marker: default\n")

      script = File.join(ROOT, '_tasks/upsert_dojos_geojson.rb')
      Dir.chdir(dir) { system(RbConfig.ruby, script, exception: true) }

      JSON.parse(File.read(File.join(dir, 'dojos.geojson')))['features']
    end
  end
end
