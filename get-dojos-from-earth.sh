curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "query": {
    "verified": 1,
    "deleted": 0,
    "fields$": [
      "name",
      "geo_point",
      "stage",
      "url_slug",
      "start_time",
      "end_time",
      "private",
      "frequency",
      "alternative_frequency",
      "day"
    ]
  }
}' 'https://zen.coderdojo.com/api/2.0/dojos' | \
  ruby -rjson \
    -e 'puts JSON.pretty_generate(JSON.parse(gets.chomp))' | \
  tee dojos_earth.json
