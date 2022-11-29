# :japan: DojoMap - 地図情報から CoderDojo を探す

地図を使って最寄りの CoderDojo を探してみよう!
https://map.coderdojo.jp/

## 使い方

1. [coderdojo.jp](https://coderdojo.jp/#dojos) の「地図情報から探す」をクリック
   ![](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-1.png?raw=true)

2. 世界地図が表示されたら近くにある CoderDojo マーカーをクリック
   ![](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-2.png?raw=true)

3. 当該 CoderDojo の連絡先情報などが表示されるので、そこから詳細へ!
   ![](https://github.com/coderdojo-japan/map.coderdojo.jp/blob/main/images/instruction-3.png?raw=true)

<br>

## セットアップ方法（開発者向け）

1. dojo一覧を取得する

```
% sh curl.sh
```

2. geojsonファイルに変換する

```
% ruby convert.rb
```

3. http serverを起動し、ブラウザで閲覧する

```
% npm install -g http-server
% http-server
% open http://localhost:8080
```

<br>

## Copyright

- :world_map: 地図情報 &copy; GSI Japan | &copy; Geolonia | &copy; OpenStreetMap
- :busts_in_silhouette: 開発者: [@champierre](https://github.com/champierre), [@yasulab](https://github.com/yasulab), and other [contributors](https://github.com/coderdojo-japan/map.coderdojo.jp/graphs/contributors).
