[![Deploy to GitHub Pages](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/deploy_to_pages.yml/badge.svg)](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/deploy_to_pages.yml) [![pages-build-deployment](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/pages/pages-build-deployment) [![Daily Update](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/scheduler_daily.yml/badge.svg)](https://github.com/coderdojo-japan/map.coderdojo.jp/actions/workflows/scheduler_daily.yml)

# :japan: DojoMap - 地図で CoderDojo を探す

CoderDojo の地図『**[DojoMap](https://map.coderdojo.jp/)**』で、
最寄りの CoderDojo を探してみよう！ :mag: :dash: 
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

スライド: [2022年度 CoderDojo Japan 活動報告 - SpeakerDeck](https://speakerdeck.com/coderdojojapan/coderdojo-japan-in-2022)<br>
解説動画: [2022年度 CoderDojo Japan 活動報告 - YouTube](https://youtu.be/m1eoqFy0BW8?t=2575)

<br>

## :gem: DojoMap のセットアップ方法（開発者向け）

1. ローカル環境で Ruby が実行できることを確認する
   ```
   $ ruby --version
   ```   

1. 利用する Ruby ライブラリをインストールする
   ```
   $ bundle install
   ```

1. [CoderDojo Zen](https://zen.coderdojo.com/) から Dojo 情報一覧を取得する（[`dojos_earth.json`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos_earth.json)が更新されます）
   ```
   $ bundle exec rake get_data_from_earth
   ```

1. [CoderDojo Japan](http://coderdojo.jp/) から Dojo 情報一覧を取得する（[`dojos_japan.json`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos_japan.json)が更新されます）
   ```
   # Japan's API からデータを取得し、ロゴ画像をキャッシングする
   $ bundle exec rake get_data_from_japan
   $ bundle exec rake cache_dojo_logos
   ```

1. 上記２つの取得結果を組み合わせて [`dojos.geojson`](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/dojos.geojson) ファイルを生成する
   ```
   $ bundle exec rake upsert_dojos_geojson
   ```

1. ローカル環境で生成された DojoMap を確認する
   ```
   # 必要なライブラリをインストール
   $ bundle install
   
   # ローカルサーバーを立ち上げる
   $ bundle exec jekyll server
   
   # ブラウザでローカルサーバーにアクセス
   $ open http://localhost:4000
   ```

![ローカル環境で確認している様子のスクショ](https://raw.githubusercontent.com/coderdojo-japan/map.coderdojo.jp/main/images/localhost.png)

<br>

## :books: 関連記事・プレスリリースなど

- [Geolonia の支援を得て、全国の CoderDojo が地図から探せる「DojoMap」を開発 - PR TIMES](https://prtimes.jp/main/html/rd/p/000000008.000038935.html)
- [子どものためのプログラミング道場「CoderDojo」を支援し、「DojoMap」を技術支援 - Geolonia blog](https://blog.geolonia.com/2022/11/30/support-coderdojo.html)
- [全国のプログラミング道場を地図上で探せるマップ「DojoMap」が公開 - GeoNews](https://geo-news.jp/archives/5499)
- [全国のコーダー道場が地図から探せる「DojoMap」、オープンソースで提供 - 高田馬場経済新聞](https://takadanobaba.keizai.biz/headline/1002/)
- [非営利のプログラミング道場「CoderDojo」を地図上で表示する「DojoMap」提供開始 - こどもとIT](https://edu.watch.impress.co.jp/docs/news/1460906.html)
- [CoderDojo Japan、Geoloniaの支援を得て地図から探せる「DojoMap」を開発 - ICT教育ニュース](https://ict-enews.net/2022/12/05coderdojo-japan/)

<br>

## :printer: 地図データを印刷するときの注意点

DojoMap の画面右下にあるクレジット表記および `openstreetmap.org/copyright` を画像に含める、もしくはテキストとして別途追記いただくことで、ワークショップや展示物としても本地図データをご活用いただけます。

- 参考: [OpenStreetMap - 著作権とライセンス](https://www.openstreetmap.org/copyright)
- 参考: [OpenStreetMap Foundation - Licence/Attribution Guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines)

> [**Books, magazines, and printed maps**](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Books,_magazines,_and_printed_maps)
> 
> For a printed map and similar media (that is ebooks, PDFs and so on), the credit must appear beside the map if that is where other such credits appear, or in a footnote/endnote if that is where other credits appear, or in the “acknowledgements” section of the publication (often at the start of a book or magazine) if that is where other credits appear. The URL to [openstreetmap.org/copyright](https://www.openstreetmap.org/copyright) must be printed out.

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

The source codes, such as HTML/CSS/JavaScript and Ruby codes not declared above, are published under **[The MIT License](https://opensource.org/licenses/MIT)** below. Feel free to refer, copy, or share them. And contact `info@coderdojo.jp` if you find anything unclear.

Copyright &copy; [一般社団法人 CoderDojo Japan](https://coderdojo.jp/about-coderdojo-japan)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
</details>

<br>

## :copyright: DojoMap's Copyright

- :world_map: 地図: &copy; [GSI Japan](https://www.gsi.go.jp/) | &copy; [Geolonia](https://geolonia.com/) | &copy; [OpenStreetMap](https://www.openstreetmap.org/)
- :busts_in_silhouette: 開発: [@champierre](https://github.com/champierre) | [@YassLab](https://github.com/yasslab) Inc. | [Contributors](https://github.com/coderdojo-japan/map.coderdojo.jp/graphs/contributors)
- :yin_yang: 運営: 一般社団法人 CoderDojo Japan ([@coderdojo-japan](https://github.com/coderdojo-japan))
