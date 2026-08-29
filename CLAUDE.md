# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

DojoMapは、全国のCoderDojoを地図上で探せるWebアプリケーションです。JekyllベースのシンプルなWebアプリで、Geolonia Mapsを使って地図を表示し、Clubs APIとCoderDojo JapanのAPIからデータを定期的に取得して更新しています。

## よく使うコマンド

### 開発環境のセットアップ
```bash
# 依存関係のインストール
bundle install
```

### データ更新

**重要**: Jekyll 4.3以降、`jekyll build`実行時に自動的にデータ更新タスクが実行されます（`_plugins/build_hooks.rb`）。

```bash
# 推奨: jekyll buildで全て自動実行
bundle exec jekyll build
# → 自動的に以下が実行されます:
#    - cache_dojo_logos
#    - upsert_dojos_geojson
#    - compact_geojson

# または個別実行（必要な場合のみ）
bundle exec rake get_data_from_earth      # 全世界のDojoデータ取得
bundle exec rake get_data_from_japan      # 日本のDojoとイベントデータ取得
bundle exec rake cache_dojo_logos         # ロゴ画像キャッシュ
bundle exec rake upsert_dojos_geojson     # GeoJSON生成
bundle exec rake compact_geojson          # GeoJSON圧縮
```

### 開発・ビルド・テスト
```bash
# ローカル開発サーバーの起動
bundle exec jekyll server

# 本番環境向けビルド
JEKYLL_ENV=production bundle exec jekyll build

# テストの実行（リンクチェックなど）
bundle exec rake test
```

## アーキテクチャと主要コンポーネント

### データフロー
1. **データ取得**: 外部APIから最新のDojo情報を取得
   - `get_dojos_from_earth.rb`: Clubs API（旧CoderDojo Zen）からワールドワイドのデータを取得
   - `get_dojos_from_japan.rb`: CoderDojo Japan APIから日本のデータを取得
   - `get_events_from_japan.rb`: 日本のイベント情報を取得

2. **データ統合**: 複数のソースから取得したデータを統合
   - `upsert_dojos_geojson.rb`: 両方のAPIから取得したデータをマージし、重複を除去してGeoJSON形式に変換

3. **画像最適化**: ロゴ画像を効率的に配信
   - `cache_dojo_logos.rb`: ロゴ画像をダウンロードしてWebP形式に変換

### Jekyllビルドフック（自動データ更新）

`_plugins/build_hooks.rb`により、`jekyll build`または`jekyll server`実行時に自動的に以下のタスクが実行されます：

```ruby
# Jekyll::Hooks.register :site, :after_init
1. upsert_dojos_geojson  # GeoJSON生成
2. compact_geojson       # GeoJSON圧縮（22.9%削減）
3. cache_dojo_logos      # Dojoロゴキャッシュ
```

**メリット**:
- ✅ ローカル開発でも本番環境でも一貫した動作
- ✅ `_data/*.json` 更新後、`jekyll build`だけで自動反映
- ✅ 手動でのRakeタスク実行が不要

**実行ログ例**:
```
🔄 Running pre-build tasks...
  → Updating dojos.geojson...
  → Creating dojos.min.geojson...
  ✅ Created dojos.min.geojson (22.9% reduction)
  → Caching dojo logos...
  ✅ Pre-build tasks completed
```

### 自動更新システム

GitHub Actionsで毎日自動更新（日本時間 5:59）:
1. データ取得スクリプトを実行
2. Jekyllビルド（プラグインが自動的にGeoJSON生成・圧縮）
3. テスト実行（安全性確認）
4. 変更があれば自動コミット
5. GitHub Pagesへ自動デプロイ

**ワークフローの手動実行**:
```bash
# scheduler_daily.yml（データ更新＋デプロイ）
gh workflow run scheduler_daily.yml

# ci.yml（ビルド・テスト・デプロイ。PR ではデプロイせずテストまで）
gh workflow run ci.yml

# 実行状況確認
gh run list --workflow=scheduler_daily.yml --limit 3
gh run watch  # リアルタイム監視
```

### 地図表示
- **Geolonia Maps**: 日本に最適化された地図タイルサービス
- **index.html**: 日本のDojoに特化した地図
- **world.html**: 世界中のDojoを表示する地図
- マーカークリックでポップアップ表示（名前、説明、連絡先、イベント情報）

### 主要ファイル
- `_data/dojos_earth.json`: Clubs APIから取得した全世界のDojoデータ
- `_data/dojos_japan.json`: CoderDojo Japan APIから取得した日本のDojoデータ
- `_data/events_japan.json`: 日本のイベントデータ
- `_data/dojo2dojo.json`: 地図に載った日本のDojo一覧（生成物）
- `tmp/unmatched_dojos.json`: 地図に載らなかったactiveなDojoと、その理由（生成物）
- `dojos.geojson`: 地図表示用の統合データ（GeoJSON形式、人間が読める形式）
- `dojos.min.geojson`: 圧縮版GeoJSON（本番環境で使用、22.9%削減）
- `_plugins/build_hooks.rb`: Jekyllビルド時の自動データ更新フック
- `images/dojos/*.webp`: 各Dojoのロゴ画像（WebP形式で最適化）

### テスト戦略
- `html-proofer`: HTMLの妥当性とリンクチェック
- 外部リンクの検証を含む包括的なチェック

## 🧠 o3 MCP価値最大化戦略

技術的に詰まったときや調査が必要なときは、o3 MCP（`mcp__o3__o3-search`）を活用して最新の情報を取得します。

### 予防的調査（エラーを未然に防ぐ）
実装前に必ずo3 MCPで以下を調査：
- 新しいGemを追加する前：`mcp__o3__o3-search "[gem名] Jekyll 4.3 Ruby 3.4 compatibility issues 2025"`
- APIエンドポイント変更前：`mcp__o3__o3-search "CoderDojo Clubs API endpoint migration breaking changes 2025"`
- GitHub Actions更新前：`mcp__o3__o3-search "GitHub Actions Ubuntu runner Jekyll build issues 2025"`

### DojoMap固有のクエリテンプレート

#### Jekyll関連
```bash
# Jekyll 4.3のビルドエラー
mcp__o3__o3-search "Jekyll 4.3 [エラーメッセージ] Ruby 3.4 GitHub Pages 2025"

# Jekyll プラグイン互換性
mcp__o3__o3-search "Jekyll 4.3 [プラグイン名] compatibility Ruby 3.4 2025"

# Liquid テンプレートエラー
mcp__o3__o3-search "Jekyll Liquid template [エラー内容] syntax error 2025"
```

#### 地図・GeoJSON関連
```bash
# Geolonia Maps API
mcp__o3__o3-search "Geolonia Maps API [機能名] implementation JavaScript 2025"

# GeoJSON フォーマット
mcp__o3__o3-search "GeoJSON format [問題] mapbox compatibility 2025"

# マーカークラスタリング
mcp__o3__o3-search "Geolonia Maps marker clustering performance optimization 2025"
```

#### API連携
```bash
# Clubs API (旧CoderDojo Zen)
mcp__o3__o3-search "CoderDojo Clubs API [エンドポイント] authentication Ruby 2025"

# APIレート制限
mcp__o3__o3-search "CoderDojo API rate limit handling Ruby retry strategy 2025"

# JSONパースエラー
mcp__o3__o3-search "[エラー全文] JSON parse Ruby 3.4 encoding UTF-8"
```

#### 画像最適化
```bash
# WebP変換
mcp__o3__o3-search "Ruby ImageMagick WebP conversion quality optimization 2025"

# 画像キャッシュ戦略
mcp__o3__o3-search "Jekyll static site image caching strategy WebP CDN 2025"
```

#### GitHub Actions
```bash
# ワークフローエラー
mcp__o3__o3-search "GitHub Actions [エラー] Jekyll build Ruby 3.4 Ubuntu 2025"

# 自動コミット問題
mcp__o3__o3-search "GitHub Actions automated commit permission denied GITHUB_TOKEN 2025"

# GitHub Pages デプロイ
mcp__o3__o3-search "GitHub Actions Pages deploy Jekyll JEKYLL_ENV production 2025"
```

### 段階的問題解決アプローチ
1. **初期調査**: エラーメッセージ全文で検索
2. **深堀り**: 使用している技術スタック（Jekyll 4.3, Ruby 3.4, Geolonia Maps）を含めて再検索
3. **検証**: 公式ドキュメントや最新のGitHub Issuesを確認

#### データ統合問題
```bash
# 複数データソース統合時の名前マッチング問題
mcp__o3__o3-search "GeoJSON data integration name mapping mismatch multiple sources 2025"

# ID ベースでのデータ突合
mcp__o3__o3-search "stable identifier vs name matching data integration best practices 2025"

# データ不整合のデバッグ手法
mcp__o3__o3-search "multi-source data integration debugging missing records troubleshooting 2025"
```

### 結果の批判的評価
o3の検索結果を使用する際は必ず：
1. 情報の日付を確認（2024年以降の情報を優先）
2. Jekyll/Ruby/APIのバージョン互換性を確認
3. DojoMapの制約条件（静的サイト、GitHub Pages）と照合
4. 小規模な変更でテストしてから本実装

## トラブルシューティング

### データ統合で特定のDojoが地図に表示されない場合

Clubs DB と Japan DB は `global_club_id` (UUID) で突合している。表示されない場合、
ほぼ全て「UUID が一致していない」ことが原因なので、まず生成物の診断結果を見る。

1. **地図に載らなかった Dojo と理由を確認する**
   ```bash
   bundle exec rake upsert_dojos_geojson
   cat tmp/unmatched_dojos.json
   ```

   `reason` の意味は次のとおり。

   | reason | 意味 | 対応 |
   |---|---|---|
   | `uuid_not_in_clubs` | coderdojo.jp の `global_club_id` が指すクラブが Clubs DB に無い | Clubs 側で削除・ID 変更が起きている。`db/dojos.yml` の値を現在のものに更新する |
   | `club_excluded_by_status_or_coordinates` | クラブはあるが、座標が無いか活動中ではない | Clubs 側の登録内容を直す（提携先の管理画面） |
   | `no_uuid` | coderdojo.jp 側に `global_club_id` が無い | `db/dojos.yml` に設定する。通常は向こうの CI が防ぐ |

2. **Clubs DB 側の現在の UUID を調べる**
   ```bash
   ruby -rjson -e 'JSON.parse(File.read("_data/dojos_earth.json")).select { |c| c["countryCode"] == "JP" && c["name"].include?("対象名") }.each { |c| puts "#{c["id"]} #{c["name"]} #{c["status"]}" }'
   ```

3. **coderdojo.jp 側を直す**

   `db/dojos.yml` の `global_club_id` を更新し、PR を出す。地図側のリポジトリで
   修正することはない（名前で突合していた頃と違い、こちらに手動のマッピングは無い）。

4. **反映を確認する**
   ```bash
   bundle exec rake get_data_from_japan   # coderdojo.jp のデプロイ完了後に実行
   bundle exec rake upsert_dojos_geojson
   bundle exec rake test_matching
   ```

### 名前での突合をやめた理由

以前は `dojo2dojo.csv` で「Japan 登録名 → Clubs 登録名」を手で対応付けていたが、
次の理由で UUID 突合に切り替えた。

- 新しい Dojo を追加するたび CSV に 1 行足す運用が必要で、実際に漏れていた
- Clubs 側で改名されると追従できない（例: 那覇は「CoderDojo Japan Association
  (Official Regional Body)」に変わっていて名前が一致しなかった）
- 同名クラブが二重登録されていると、先に現れた方を拾ってしまう（流山・古河）
- 表記ゆれ（"Coderdojo XXX" vs "XXX"、"@" や "、" の有無、ローマ字と日本語）に
  そのつど対応する必要があった