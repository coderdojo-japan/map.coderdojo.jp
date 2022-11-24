require 'json'

dojos = []

File.open("dojos.json") do |file|
  dojos = JSON.load(file)
end

features = []
dojos.each do |dojo|
  # 活動していない道場は除外
  #
  # stage:
  # 0: In planning
  # 1: Open, come along
  # 2: Register ahead
  # 3: 満員
  # 4: 活動していません
  if dojo["geoPoint"] && dojo["stage"] != 4
    features << {
      "type" => "Feature",
      "geometry" => {
        "type" => "Point",
        "coordinates" => [dojo["geoPoint"]["lon"], dojo["geoPoint"]["lat"]]
      },
      "properties" => {
        "description" => "#{dojo['name']}<br /><a target='_blank' href='http://zen.coderdojo.com/dojos/#{dojo['urlSlug']}'>zen</a>"
      }
    }
  end
end

geojson = {
  "type": "FeatureCollection",
  "features": features
}

File.open("dojos.geojson", "w") do |file|
  JSON.dump(geojson, file)
end
