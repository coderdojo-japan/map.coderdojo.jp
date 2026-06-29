#!/usr/bin/env ruby
# frozen_string_literal: true

# 地図にマーカーが表示されなくなる回帰を防ぐためのテスト。
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
