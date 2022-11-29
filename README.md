# :japan: DojoMap - 地図で CoderDojo を探す

CoderDojo の地図『**[DojoMap](https://map.coderdojo.jp/)**』で、
最寄りの CoderDojo を探してみよう！:mag: :dash: 
https://map.coderdojo.jp/

[![DojoMap](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/cover.png?raw=true)](https://map.coderdojo.jp/)

<br>

## :beginner: DojoMap の使い方

1. **:japan: [coderdojo.jp](https://coderdojo.jp/#dojos) の「地図情報から探す」をクリック**
   [![CoderDojo Japan](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-1.png?raw=true)](https://coderdojo.jp/#dojos)

2. **:world_map: 地図情報が表示されたら気になる CoderDojo マーカーをクリック**
   [![DojoMap](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-2.png?raw=true)](https://map.coderdojo.jp/)

3. **:yin_yang: CoderDojo の連絡先情報などが表示されるので、そこから詳細へ GO!**
   [![CoderDojo 富山](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-3.png?raw=true)](https://toyamanagaejp.wixsite.com/website)

スライド: [2022年度 CoderDojo Japan 活動報告 - SpeakerDeck](https://speakerdeck.com/coderdojojapan/coderdojo-japan-in-2022)
解説動画: [2022年度 CoderDojo Japan 活動報告 - YouTube](https://youtu.be/m1eoqFy0BW8?t=2575)

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

## :credit_card: License

<details>
  <summary><strong>Check out each license</strong></summary>
  
This web application is developed with many other brilliant works!   
Check out the followings if you are interested in. :wink:

<h3>Libraries & Icons</h3>

The libraries like [RubyGems](https://rubygems.org/) used in this web application have their own licenses. Say, DojoMap uses [Jekyll](https://jekyllrb.com/), which is licensed under the terms of the [MIT License](http://opensource.org/licenses/MIT).

This repository may also use icons created by [Font Awesome](http://fontawesome.io/), licensed under SIL OFL 1.1, and [Twemoji](https://github.com/twitter/twemoji), created by Twitter, licensed under the [MIT License](http://opensource.org/licenses/MIT).

Thanks for their great works to make this app published! :sparkling_heart: 

<h3>Logos & Photos</h3>

The images, such as logos and photos of [each dojo](http://coderdojo.jp/#dojos), are NOT published under the following license. Contact its owner, like the maintainer of linked external website, before using them. :relieved: 

<h3>Codes & Others</h3>

The source codes, such as HTML/CSS/JavaScript and Ruby codes not declared above, are published under **[The MIT License](https://opensource.org/licenses/MIT)** below. Feel free to refer, copy, or share them. And contact `info@coderdojo.jp` if you find something unclear.

Copyright &copy; [一般社団法人 CoderDojo Japan](https://coderdojo.jp/about-coderdojo-japan)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
</details>

<br>

## :copyright: DojoMap's Copyright

- :world_map: 地図情報: &copy; [GSI Japan](https://www.gsi.go.jp/) | &copy; [Geolonia](https://geolonia.com/) | &copy; [OpenStreetMap](https://www.openstreetmap.org/)
- :busts_in_silhouette: 開発者: [@champierre](https://github.com/champierre) | [@yasulab](https://github.com/yasulab) | other [contributors](https://github.com/coderdojo-japan/map.coderdojo.jp/graphs/contributors)
- :yin_yang: 運営社: [一般社団法人 CoderDojo Japan](https://coderdojo.jp/about-coderdojo-japan)
