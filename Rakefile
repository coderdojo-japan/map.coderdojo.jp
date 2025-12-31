task default: 'test'

# These tasks are executed in GitHub Actions
desc 'Get CoderDojo data on the Earth via Raspberry Pi Clubs API'
task(:get_data_from_earth)  { ruby '_tasks/get_data_from_earth.rb'  }
task(:get_data_from_japan)  { ruby '_tasks/get_data_from_japan.rb'  }
task(:cache_dojo_logos)     { ruby '_tasks/cache_dojo_logos.rb'     }
task(:upsert_dojos_geojson) { ruby '_tasks/upsert_dojos_geojson.rb' }
task(:compact_geojson)      { ruby '_tasks/compact_geojson.rb'      }

# GitHub - gjtorikian/html-proofer
# https://github.com/gjtorikian/html-proofer
require 'html-proofer'
task test: [:build] do
  #require './tests/custom_checks'
  options = {
    #checks: ['Links', 'Images', 'Scripts', 'OpenGraph', 'Favicon', 'CustomChecks'],
    checks: ['Links', 'Images', 'Scripts', 'OpenGraph', 'Favicon'],
    allow_hash_href:  true,
    disable_external: ENV['TEST_EXTERNAL_LINKS'] != 'true',
    enforce_https:    true,

    # NOTE: Ignore file, URL, and response as follows
    ignore_files: [
      /google(.*)\.html/,
    ],

    # Ignore domains that need to access by HTTP not HTTPS.
    ignore_urls: [
      /twitter.com/,  # Skip testing Twitter URLs
    ],

    #ignore_status_codes: [0, 500, 999],
  }

  HTMLProofer.check_directory('_site', options).run
end

# Enable 'build' to flush cache files via 'clean'
task build: [:clean] do
  system 'JEKYLL_ENV=test bundle exec jekyll build' unless ENV['SKIP_BUILD'] == 'true'
end

task :clean do
  system 'bundle exec jekyll clean' unless ENV['SKIP_BUILD'] == 'true'
end
