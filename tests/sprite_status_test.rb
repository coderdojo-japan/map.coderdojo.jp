#!/usr/bin/env ruby
# frozen_string_literal: true

# Geolonia スプライト サーバの健全性を手動で確認するためのテスト。
#
# == 用途 ==
# マーカーは Geolonia のスプライト サーバ
# (https://api.geolonia.com/v1/sprites/...) からアイコン画像を取得して描画する。
# このサーバが 502 等で落ちると marker-symbol ベースのマーカーが全滅する
# （2026/06 の不具合の真因）。本テストはその状態を手動で検査する。
#
# == CI には統合しない ==
# 外部サービスの瞬間的な状態に CI/デプロイを依存させない（赤くしない）ため、
# `rake test` には含めない。必要なときに手動で実行する:
#   GEOLONIA_API_KEY=xxxx bundle exec rake test_sprite
#   (または GEOLONIA_API_KEY=xxxx ruby tests/sprite_status_test.rb)
#
# == セキュリティ ==
# Geolonia の埋め込みキーはクライアント用の公開キー（公開サイトの HTML に既に
# 埋め込み済み）。ドメイン制限で保護される種類。とはいえ本テストは URL や
# キーをログに出さず、HTTP ステータスと coderdojo の有無だけを出力する。

require 'minitest/autorun'
require 'json'
require 'net/http'
require 'uri'

SPRITE_BASE = 'https://api.geolonia.com/v1/sprites/basic-v1@2x'

class SpriteStatusTest < Minitest::Test
  def setup
    @key = ENV['GEOLONIA_API_KEY'].to_s
    skip 'GEOLONIA_API_KEY が未設定です（手動実行時に環境変数で渡してください）' if @key.empty?

    uri = URI("#{SPRITE_BASE}.json?key=#{@key}")
    @response = Net::HTTP.get_response(uri)
  rescue StandardError => e
    @error = e
  end

  # スプライト JSON が正常(200)に返るか
  def test_sprite_endpoint_is_healthy
    flunk "スプライト取得で通信エラー: #{@error.class}: #{@error.message}" if @error

    assert_equal '200', @response.code,
                 "Geolonia スプライト サーバが正常応答していません (HTTP #{@response.code})。" \
                 'marker-symbol ベースのマーカーは描画されません。' \
                 '_config.yml は marker: default（スプライト非依存）を推奨します。'
  end

  # スプライトに 'coderdojo' シンボルが含まれるか（coderdojo モードが使えるか）
  def test_sprite_contains_coderdojo_symbol
    flunk "スプライト取得で通信エラー: #{@error.class}: #{@error.message}" if @error
    skip "スプライトが 200 を返していません (HTTP #{@response.code})" unless @response.code == '200'

    symbols = JSON.parse(@response.body)
    assert symbols.key?('coderdojo'),
           "スプライトに 'coderdojo' シンボルがありません（含まれるシンボル数: #{symbols.size}）。" \
           'marker: coderdojo に切り替えてもロゴ マーカーは描画されません。'
  end
end
