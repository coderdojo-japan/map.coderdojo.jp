#!/usr/bin/env ruby
# frozen_string_literal: true

# Geolonia スプライト サーバの健全性を確認するテスト。
#
# 関連 PR: https://github.com/coderdojo-japan/map.coderdojo.jp/pull/28
#
# == 用途 ==
# マーカーは Geolonia のスプライト サーバからアイコン画像を取得して描画する。
# このサーバから正常な応答が得られないと marker-symbol ベースのマーカーが描画されない
# （2026/06 の不具合の原因）。本テストはその状態を検査する。
#
# == 実行方法 ==
# scheduler_daily.yml から毎日実行され、失敗すると Slack に通知される。
# 手動実行する場合:
#   GEOLONIA_API_KEY=xxxx ruby tests/sprite_status_test.rb
#
# == デプロイは止めない ==
# 外部サービスの状態でデプロイを止めてはならない（依存先に異常がある時こそ
# marker: default への切替をデプロイしたい）。そのため `rake test` には含めず、
# ワークフロー側で continue-on-error として実行する。
#
# == セキュリティ ==
# Geolonia の埋め込みキーはクライアント用の公開キー（公開サイトの HTML に既に
# 埋め込み済み）。ドメイン制限で保護される種類。とはいえ本テストは URL や
# キーをログに出さず、HTTP ステータスだけを出力する。

require 'minitest/autorun'
require 'json'
require 'net/http'
require 'uri'

# 埋め込み v5 が使うスタイル (basic-v2) のスプライト。
# 2026/07 時点で api.geolonia.com は cdn.geolonia.com へ 302 リダイレクトするため、
# リダイレクトを追う必要がある（追わないと 302 を異常と誤検知し、毎日誤報が飛ぶ）。
SPRITE_URL = 'https://api.geolonia.com/v1/sprites/basic-v2.json'

class SpriteStatusTest < Minitest::Test
  def setup
    @key = ENV['GEOLONIA_API_KEY'].to_s
    skip 'GEOLONIA_API_KEY が未設定です' if @key.empty?

    @response = fetch_following_redirects(URI("#{SPRITE_URL}?key=#{@key}"))
  rescue StandardError => e
    @error = e
  end

  # スプライト サーバから正常な応答が得られるか。
  # 応答が得られないと marker-symbol ベースのマーカーが描画されない。
  def test_sprite_endpoint_is_healthy
    flunk "スプライト取得で通信エラー: #{@error.class}: #{@error.message}" if @error

    assert_equal '200', @response.code,
                 "スプライト サーバから正常な応答が得られていません (HTTP #{@response.code})。" \
                 'マーカーが描画されない可能性があります。' \
                 '暫定復旧: _config.yml の marker: coderdojo を marker: default に変更して' \
                 '再デプロイすると、スプライト非依存の circle マーカーに切り替わります。'
  end

  # 200 を返しても中身が壊れていることはある（今日の教訓: ステータスではなく中身を見る）。
  def test_sprite_json_is_parsable
    flunk "スプライト取得で通信エラー: #{@error.class}: #{@error.message}" if @error
    skip "スプライトが 200 を返していません (HTTP #{@response.code})" unless @response.code == '200'

    symbols = JSON.parse(@response.body)
    refute_empty symbols, 'スプライト JSON が空です。マーカーが描画されない可能性があります。'
  end

  # NOTE: 以前ここに「スプライトに coderdojo シンボルが含まれるか」を検査するテストがあったが、
  # 2026/07 に削除した。実測したところ basic-v1 / basic-v2 のいずれにも（API キーの有無に
  # かかわらず）coderdojo シンボルは存在しないが、マーカーは正常に CoderDojo ロゴで描画されて
  # いた（スクリーンショットで確認済み）。前提が現実と食い違っており、残すと毎日誤報が飛ぶ。
  # ロゴがどの経路で読み込まれているかは未解明。判明したら適切な監視を足すこと。

  private

  def fetch_following_redirects(uri, limit = 3)
    raise 'リダイレクトが多すぎます' if limit.zero?

    res = Net::HTTP.get_response(uri)
    return res unless res.is_a?(Net::HTTPRedirection)

    fetch_following_redirects(URI(res['location']), limit - 1)
  end
end
