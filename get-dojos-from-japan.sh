#!/bin/sh

echo 'https://coderdojo.jp/dojos.json' | \
  ruby -rjson -rnet/http \
    -e 'puts JSON.pretty_generate(JSON.parse(Net::HTTP.get URI.parse(gets.chomp)))' | \
  tee dojos_japan.json
