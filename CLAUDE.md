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
```bash
# 全世界のDojoデータを取得（Clubs APIから）
bundle exec rake get_data_from_earth

# 日本のDojoとイベントデータを取得（CoderDojo Japan APIから）
bundle exec rake get_data_from_japan

# ロゴ画像をダウンロードしてWebP形式でキャッシュ
bundle exec rake cache_dojo_logos

# GeoJSONファイルを生成（全データを統合）
bundle exec rake upsert_dojos_geojson
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

### 自動更新システム
GitHub Actionsで毎日自動更新（日本時間 5:59）:
1. データ取得スクリプトを実行
2. 変更があれば自動コミット
3. GitHub Pagesへ自動デプロイ

### 地図表示
- **Geolonia Maps**: 日本に最適化された地図タイルサービス
- **index.html**: 日本のDojoに特化した地図
- **world.html**: 世界中のDojoを表示する地図
- マーカークリックでポップアップ表示（名前、説明、連絡先、イベント情報）

### 主要ファイル
- `dojos_earth.json`: Clubs APIから取得した全世界のDojoデータ
- `dojos_japan.json`: CoderDojo Japan APIから取得した日本のDojoデータ
- `events_japan.json`: 日本のイベントデータ
- `dojos.geojson`: 地図表示用の統合データ（GeoJSON形式）
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

### 結果の批判的評価
o3の検索結果を使用する際は必ず：
1. 情報の日付を確認（2024年以降の情報を優先）
2. Jekyll/Ruby/APIのバージョン互換性を確認
3. DojoMapの制約条件（静的サイト、GitHub Pages）と照合
4. 小規模な変更でテストしてから本実装