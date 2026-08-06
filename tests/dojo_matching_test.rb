#!/usr/bin/env ruby
# frozen_string_literal: true

# 日本のマーカーが静かに消える回帰を防ぐためのテスト。
#
# == 背景 ==
# 突合を dojo2dojo.csv の名前照合から global_club_id (UUID) 直結に切り替えた。
# 名前照合には「新しい Dojo のたびに CSV へ 1 行足す」運用が必要で、実際に漏れが
# 起きていた。また Clubs 側で改名されると追従できなかった。
#
# == なぜテストが要るか ==
# このリポジトリは日次の GitHub Actions が生成物を作ってそのままデプロイする。
# 人のレビューが入らないため、入力データが壊れても気づけない。
#
# 実際に、名前照合には「壊れても縮退して生き延びる」性質があった。
# _data/dojos_japan.json が空でも、CSV とローカルのデータだけで日本のマーカーは
# 出ていた（ロゴがデフォルトになるだけ）。UUID 直結にはその性質が無く、
# 入力が空なら日本のマーカーは全滅する。海外分 1,100 件あまりは残るので、
# GeoJSON の妥当性を見るテストでは検出できない。
#
# ここでは入力（dojos_japan.json）と出力（dojo2dojo.json）の両側に下限を置く。
#
# 実行: bundle exec rake test_matching  (または ruby tests/dojo_matching_test.rb)

require 'minitest/autorun'
require 'json'

ROOT        = File.expand_path('..', __dir__)
JAPAN_PATH  = File.join(ROOT, '_data', 'dojos_japan.json')
MARKER_PATH = File.join(ROOT, '_data', 'dojo2dojo.json')

# 下限は「明らかに壊れている」ことだけを検出する値にする。
# 実測 339 件・202 マーカー（2026-08 時点）に対して十分な余裕を取り、
# 道場が減る通常の変動では落ちないようにする。
MIN_JAPAN_DOJOS = 300
MIN_WITH_UUID   = 150
MIN_JP_MARKERS  = 150

UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

def japan_dojos  = JSON.parse(File.read(JAPAN_PATH))
def jp_markers   = JSON.parse(File.read(MARKER_PATH))

# 入力: coderdojo.jp から取得した /dojos.json
class JapanDataIntegrityTest < Minitest::Test
  def test_has_enough_dojos
    # 空配列や取得失敗をここで止める。取得スクリプトには件数チェックが無い
    assert_operator japan_dojos.size, :>=, MIN_JAPAN_DOJOS,
      "dojos_japan.json が #{japan_dojos.size} 件しかありません。取得に失敗した可能性があります"
  end

  def test_every_dojo_has_is_active_key
    # 突合は is_active == false だけを除外し、nil は通す。キーが消えると
    # 休止中の道場が地図に出てしまうため、キーの存在を保証する
    missing = japan_dojos.reject { |d| d.key?('is_active') }
    assert_empty missing.map { |d| d['name'] },
      'is_active キーを持たない Dojo があります'
  end

  def test_has_enough_global_club_ids
    with_uuid = japan_dojos.count { |d| d['global_club_id'] }
    assert_operator with_uuid, :>=, MIN_WITH_UUID,
      "global_club_id を持つ Dojo が #{with_uuid} 件しかありません。" \
      'カラムが消えたか、API の応答が変わった可能性があります'
  end

  def test_global_club_ids_are_valid_uuids
    invalid = japan_dojos.select { |d| d['global_club_id'] }
                         .reject  { |d| d['global_club_id'].match?(UUID_FORMAT) }
    assert_empty invalid.map { |d| "#{d['name']}: #{d['global_club_id']}" },
      'global_club_id が UUID 形式ではありません'
  end

  def test_global_club_ids_are_unique
    # 2 つの Dojo が同じ UUID を持つと、突合の Hash が後勝ちになり
    # 片方が地図から静かに消える
    ids = japan_dojos.filter_map { |d| d['global_club_id'] }
    assert_empty ids.tally.select { |_, n| n > 1 }.keys,
      '同じ global_club_id を持つ Dojo があります'
  end
end

# 出力: 地図に載った日本のクラブ
class JapanMarkerTest < Minitest::Test
  def test_has_enough_markers
    # 突合が全面的に失敗した状態（Clubs 側の UUID 一斉変更など）を止める
    assert_operator jp_markers.size, :>=, MIN_JP_MARKERS,
      "日本のマーカーが #{jp_markers.size} 件しかありません。突合に失敗した可能性があります"
  end

  def test_no_dojo_appears_twice
    # Clubs 側には同名クラブの二重登録が実在するため（流山・古河）、
    # 1 つの Dojo に 2 つのマーカーが出ていないかを名前で数えて確かめる
    duplicated = jp_markers.group_by { |d| d['name_japan'] }.select { |_, v| v.size > 1 }
    assert_empty duplicated.keys,
      "同じ Dojo に複数のマーカーが出ています: #{duplicated.keys.join(', ')}"
  end
end
