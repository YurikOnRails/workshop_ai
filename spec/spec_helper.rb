# frozen_string_literal: true

require 'bundler/setup'
require 'rspec/its'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Print the 10 slowest examples and example groups at the end of the spec run
  config.profile_examples = 10 if config.files_to_run.one?

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed
end
