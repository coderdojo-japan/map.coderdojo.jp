source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'jekyll'

group :jekyll_plugins do
  gem 'jekyll-sitemap'

  # No need this gem because we build by GitHub Actions and
  # serve the built results (static files) on GitHub Pages.
  # gem 'github-pages'
end

# Declare to install bundled gems to fix warnings:
# https://www.ruby-lang.org/ja/news/2023/12/25/ruby-3-3-0-released/
gem 'csv'
gem 'base64'
gem 'bigdecimal'
