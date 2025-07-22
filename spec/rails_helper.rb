# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rspec/rails'
require 'shoulda/matchers'
require 'webmock/rspec'
require 'vcr'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include ActiveSupport::Testing::TimeHelpers for time travel in tests
  config.include ActiveSupport::Testing::TimeHelpers

  # Use the shoulda-matchers configuration
  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Include Devise test helpers if needed
  # config.include Devise::Test::ControllerHelpers, type: :controller
  # config.include Devise::Test::IntegrationHelpers, type: :request

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed

  # Configure FactoryBot
  config.before(:suite) do
    # Reset FactoryBot to ensure clean state for FactoryBot 6.5.4
    FactoryBot.rewind_sequences if FactoryBot.respond_to?(:rewind_sequences)

    # Clear all factory registrations
    FactoryBot.factories.clear
    FactoryBot.sequences.clear if FactoryBot.respond_to?(:sequences)

    # Clear any cached factories
    if defined?(FactoryBot::Internal)
      FactoryBot::Internal.factories.clear
      FactoryBot::Internal.sequences.clear
      FactoryBot::Internal.traits.clear
    end

    # Reload factories
    FactoryBot.reload

    # Verify factories loaded correctly
    unless FactoryBot.factories.registered?(:chat_user)
      raise "Failed to load chat_user factory"
    end

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Configure VCR
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock
    c.configure_rspec_metadata!
    c.allow_http_connections_when_no_cassette = true
  end
end
