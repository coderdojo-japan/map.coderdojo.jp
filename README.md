# :japan: DojoMap - 地図で CoderDojo を探す

CoderDojo の地図『**[DojoMap](https://map.coderdojo.jp/)**』で、
最寄りの CoderDojo を探してみよう！:mag: :dash: 
https://map.coderdojo.jp/

<br>

## :beginner: DojoMap の使い方

1. **:japan: [coderdojo.jp](https://coderdojo.jp/#dojos) の「地図情報から探す」をクリック**
   [![CoderDojo Japan](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-1.png?raw=true)](https://coderdojo.jp/#dojos)

2. **:world_map: 地図情報が表示されたら気になる CoderDojo マーカーをクリック**
   [![DojoMap](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-2.png?raw=true)](https://map.coderdojo.jp/)

3. **:yin_yang: CoderDojo の連絡先情報などが表示されるので、そこから詳細へ GO!**
   [![CoderDojo 富山](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-3.png?raw=true)](https://toyamanagaejp.wixsite.com/website)

引用元: [2022年度 CoderDojo Japan 活動報告 - SpeakerDeck](https://speakerdeck.com/coderdojojapan/coderdojo-japan-in-2022)

<br>

## :gem: DojoMap のセットアップ方法（開発者向け）

1. CoderDojo Zen から Dojo 情報一覧を取得する（[`dojos_earth.json`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos_earth.json)にある位置情報が欲しい）
   ```
   $ ./get-dojos-from-earth.sh
   ```

1. CoderDojo Japan から Dojo 情報一覧を取得する（[`dojos_japan.json`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos_japan.json)にある詳細情報が欲しい）
   ```
   $ ./get-dojos-from-japan.sh
   ```

1. 上記２つの取得結果を組み合わせて [`dojos.geojson`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos.geojson) ファイルを生成する
   ```
   $ ./upsert_dojos_geojson.rb
   ```

1. ローカル環境で生成された DojoMap を確認する
   ```
   # Ruby が入っていることを確認
   $ ruby --version
   
   # 必要なライブラリをインストール
   $ bundle install
   
   # ローカルサーバーを立ち上げる
   $ bundle exec jekyll server
   
   # ブラウザでローカルサーバーにアクセス
   $ open http://localhost:4000
   ```

![ローカル環境で確認している様子のスクショ](https://raw.githubusercontent.com/coderdojo-japan/map.coderdojo.jp/main/images/how-to-setup.png)

<br>

## :copyright: DojoMap's Copyright

- :world_map: 地図情報: &copy; [GSI Japan](https://www.gsi.go.jp/) | &copy; [Geolonia](https://geolonia.com/) | &copy; [OpenStreetMap](https://www.openstreetmap.org/)
- :busts_in_silhouette: 開発者: [@champierre](https://github.com/champierre), [@yasulab](https://github.com/yasulab), and other [contributors](https://github.com/coderdojo-japan/map.coderdojo.jp/graphs/contributors).
- :yin_yang: 運営社: [一般社団法人 CoderDojo Japan](https://coderdojo.jp/about-coderdojo-japan)
