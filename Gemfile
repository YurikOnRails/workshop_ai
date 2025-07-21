source "https://rubygems.org"
ruby '3.4.4'

# Core
gem 'rails', '~> 8.0.2'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.4', '>= 6.4.0'
gem 'importmap-rails'
gem 'propshaft'

# Authentication
gem 'omniauth-github', '~> 2.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

# Frontend
gem 'tailwindcss-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3', '>= 1.3.3'
gem 'turbo-rails', '~> 2.0', '>= 2.0.4'

# Background jobs
gem 'solid_queue', '~> 1.0.0'

# Environment variables
gem 'dotenv-rails', '~> 2.8', '>= 2.8.1', groups: [:development, :test]

# Testing
group :development, :test do
  gem 'rspec-rails', '~> 6.1', '>= 6.1.1'
  gem 'factory_bot_rails', '~> 6.4', '>= 6.4.4'
  gem 'faker', '~> 3.3', '>= 3.3.1'
  gem 'webmock', '~> 3.23', '>= 3.23.0'
  gem 'vcr', '~> 6.2', '>= 6.2.0'
  gem 'rubocop-rails', '~> 2.25', '>= 2.25.1', require: false
end

group :development do
  gem 'web-console', '>= 4.2.0'
  gem 'listen', '~> 3.8'
  gem 'spring', '~> 4.1'
  gem 'solargraph', '~> 0.50.0'
end

group :test do
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver', '~> 4.15'
  gem 'webdrivers', '~> 5.2'
  gem 'shoulda-matchers', '~> 6.1'
  gem 'database_cleaner-active_record', '~> 2.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Database adapters
gem "solid_cache"
gem "solid_queue", "~> 1.0.0"
gem "solid_cable"

# Performance
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

# HTTP client
gem "faraday"

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end
