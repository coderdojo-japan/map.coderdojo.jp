# Pre-build tasks that run before Jekyll builds the site
Jekyll::Hooks.register :site, :after_init do |site|
  puts "🔄 Running pre-build tasks..."

  # Update GeoJSON data
  puts "  → Updating dojos.geojson..."
  system('bundle exec rake upsert_dojos_geojson')

  # Compact GeoJSON for production
  puts "  → Creating dojos.min.geojson..."
  system('bundle exec rake compact_geojson')

  # Cache dojo logos
  puts "  → Caching dojo logos..."
  system('bundle exec rake cache_dojo_logos')

  puts "✅ Pre-build tasks completed"
end
