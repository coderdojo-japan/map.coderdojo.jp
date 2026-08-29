# Pre-build tasks that run before Jekyll builds the site
Jekyll::Hooks.register :site, :after_init do |site|
  puts "🔄 Running pre-build tasks..."

  # 終了コードを見る (exception: true)。見ないと、生成が失敗しても Jekyll の
  # ビルドは成功し、コミット済みの古い dojos.geojson がそのまま出荷される。
  # 突合を global_club_id に切り替えてこの生成への依存が上がったため、
  # 静かに古い地図を出すより、ここで止める方が安全。
  # cf. https://github.com/coderdojo-japan/map.coderdojo.jp/pull/42

  # Update GeoJSON data
  puts "  → Updating dojos.geojson..."
  system('bundle exec rake upsert_dojos_geojson', exception: true)

  # Compact GeoJSON for production
  puts "  → Creating dojos.min.geojson..."
  system('bundle exec rake compact_geojson', exception: true)

  puts "✅ Pre-build tasks completed"
end
