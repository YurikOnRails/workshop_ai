# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    puts "Loading factories..."
    puts "Current factories before loading: #{FactoryBot.factories.count}"
    
    # Print all registered factories before loading
    puts "Registered factories before load:"
    FactoryBot.factories.each { |f| puts "- #{f.name}" }
    
    # Clear existing factories
    puts "Clearing existing factories..."
    FactoryBot.factories.clear
    
    # Load factories
    puts "Loading factory definitions..."
    FactoryBot.find_definitions
    
    # Print loaded factories
    puts "\nLoaded #{FactoryBot.factories.count} factories:"
    FactoryBot.factories.each { |f| puts "- #{f.name}" }
    
    # Check for duplicates
    factory_names = FactoryBot.factories.map(&:name)
    duplicate_factories = factory_names.group_by { |name| name }.select { |_, names| names.size > 1 }.map(&:first)
    
    if duplicate_factories.any?
      puts "\nWARNING: Found duplicate factories: #{duplicate_factories.join(', ')}"
      puts "This may cause issues with your tests."
    else
      puts "\nNo duplicate factories found."
    end
  end
end
