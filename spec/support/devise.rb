RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :feature
  
  # For controller tests (if using Devise's controller test helpers)
  config.include Devise::Test::ControllerHelpers, type: :controller
  
  # For view specs
  config.include Devise::Test::ControllerHelpers, type: :view
  
  # For feature specs
  config.include Warden::Test::Helpers, type: :feature
  
  # Clean up after each test
  config.after(:each) do
    Warden.test_reset!
  end
end
