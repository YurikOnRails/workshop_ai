source "https://rubygems.org"
ruby "3.4.4"

# Core
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.1"
gem "puma", "~> 6.4", ">= 6.4.0"
gem "importmap-rails"
gem "propshaft"

# Authentication
gem "omniauth-github", "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0"

# Frontend
gem "tailwindcss-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3", ">= 1.3.3"
gem "turbo-rails", "~> 2.0", ">= 2.0.4"

# Background jobs
gem "solid_queue", "~> 1.0.0"

# Environment variables
gem "dotenv-rails", "~> 2.8.1", groups: [:development, :test]

# Development & Test gems
group :development, :test do
  # Testing framework
  gem 'rspec-rails', '~> 6.1.1'
  
  # Test data generation
  gem 'factory_bot_rails', '~> 6.4.4'
  gem 'faker', '~> 3.3.1'
  
  # Test coverage
  gem 'simplecov', require: false
  
  # HTTP stubbing
  gem 'webmock', '~> 3.23.0'
  gem 'vcr', '~> 6.2.0'
  
  # Authentication
  gem 'devise', '~> 4.9.4'
  gem 'devise-jwt', '~> 0.11.0'
  
  # Feature tests
  gem 'capybara', '~> 3.40.0'
  gem 'selenium-webdriver', '~> 4.10'
  gem 'webdrivers', '~> 5.3'
  
  # Test helpers
  gem 'shoulda-matchers', '~> 6.0.0'
  gem 'database_cleaner-active_record', '~> 2.1.0'
  gem 'rspec_junit_formatter', '~> 0.6.0'
  
  # Debugging
  gem 'web-console', '~> 4.2.1'
  
  # Code quality
  gem 'rubocop-rails', '~> 2.30.0', require: false
  gem 'rubocop-rails-omakase', '~> 1.1.0', require: false
  gem 'brakeman', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
end

group :development do
  # Development server
  gem 'listen', '~> 3.8.0'
  gem 'spring', '~> 4.1.1'
  
  # Documentation
  gem 'solargraph', '~> 0.50.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Database adapters
gem "solid_cache"
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


