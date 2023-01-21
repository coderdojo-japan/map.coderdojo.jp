# GitHub Gist - Environment variables in Jekyll templates
# https://gist.github.com/nicolashery/5756478

# Plugin to add environment variables to the `site` object in Liquid templates

module Jekyll
  class EnvironmentVariables < Generator
    def generate(site)
      site.config['env'] = {}
      site.config['env']['GEOLONIA_API_KEY'] = ENV['GEOLONIA_API_KEY'] || 'YOUR-API-KEY'
      site.config['env']['JEKYLL_ENV']       = ENV['JEKYLL_ENV']       || 'development'
      # Add other environment variables to `site.config` here...
    end
  end
end
