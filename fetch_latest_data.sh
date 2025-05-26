#!/bin/sh

bundle exec rake get_data_from_earth  # Dojo 情報一覧を取得
bundle exec rake get_data_from_japan  # Japan's API からデータを取得
bundle exec rake cache_dojo_logos     # 取得したロゴ画像をキャッシュ
bundle exec rake upsert_dojos_geojson # 上記データから GeoJSON を生成
