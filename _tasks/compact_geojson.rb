#!/usr/bin/env ruby
require 'json'

# dojos.geojson とモード別バリアント(dojos.default.geojson 等)の最小化版を生成する。
# 本番 index.html は dojos.min.geojson を、テストページ /#{mode}.html は
# dojos.#{mode}.min.geojson を読み込む。
sources = Dir.glob("dojos*.geojson").reject { |path| path.end_with?(".min.geojson") }.sort

sources.each do |src|
  dest    = src.sub(/\.geojson\z/, ".min.geojson")
  geojson = JSON.load(File.read(src))

  # Write minified version (no whitespace)
  File.open(dest, 'w') { |file| JSON.dump(geojson, file) }

  reduction = ((File.size(src) - File.size(dest)) * 100.0 / File.size(src)).round(1)
  puts "✅ Created #{dest}"
  puts "   Original: #{(File.size(src) / 1024.0).round(1)} KB"
  puts "   Minified: #{(File.size(dest) / 1024.0).round(1)} KB"
  puts "   Reduction: #{reduction}%"
end
