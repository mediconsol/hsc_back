ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

# Test coverage configuration
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'
end

# Factory Bot configuration
FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
FactoryBot.find_definitions

# Database Cleaner configuration
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :transaction

class ActiveSupport::TestCase
  # Database cleaner setup
  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end
end

module ActiveSupport
  class TestCase
    # Include Factory Bot methods
    include FactoryBot::Syntax::Methods
    
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    
    # Authentication helper methods for API testing
    def auth_headers_for(user)
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{generate_test_token(user)}"
      }
    end
    
    def auth_headers
      auth_headers_for(users(:admin_user))
    end
    
    def generate_test_token(user)
      # Mock JWT token for testing
      "test-token-#{user.id}-#{user.email}"
    end
    
    # Mock current_user for controller tests
    def mock_current_user(user)
      ApplicationController.any_instance.stubs(:current_user).returns(user)
      ApplicationController.any_instance.stubs(:authenticate_user!).returns(true)
    end
  end
end
