#!/bin/sh
curl -X GET --header 'Content-Type: application/json' --header 'Accept: application/json' \
     'https://coderdojo.jp/dojos.json' --output dojos_japan.json

