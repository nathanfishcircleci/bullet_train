# Simplecov config has to come before literally everything else
# Open coverage/index.html in your browser after
# running your tests for test coverage results.
require "simplecov"
SimpleCov.command_name "test" + (ENV["TEST_ENV_NUMBER"] || "")
SimpleCov.start "rails" do
  # By default we don't include avo in coverage reports since it's not user-facing application code.
  # If you want to get test coverage for your avo resources, you can comment out or remove the next line.
  add_filter "/avo/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Set the default language we test in to English.
I18n.default_locale = :en

# We've started loading seeds by default to try to reduce any duplication of effort trying to get the test
# environment to look the same as the actual development and production environments. This means a consolidation
# of setup for things like the plans available for subscriptions and which outgoing webhooks are available to users.
require File.expand_path("../../db/seeds", __FILE__)

if ENV["KNAPSACK_PRO_CI_NODE_INDEX"].present?
  require "knapsack_pro"
  knapsack_pro_adapter = KnapsackPro::Adapters::MinitestAdapter.bind
  knapsack_pro_adapter.set_test_helper_path(__FILE__)
else
  require "colorize"
  puts "Not requiring Knapsack Pro.".yellow
  puts "If you'd like to use Knapsack Pro make sure that you've set the environment variable KNAPSACK_PRO_CI_NODE_INDEX".yellow
end

require "sidekiq/testing"
Sidekiq::Testing.inline!

ENV["MINITEST_REPORTERS_REPORTS_DIR"] = "test/reports#{ENV["TEST_ENV_NUMBER"] || ""}"
require "minitest/reporters"

# Configure Allure reporting (works in both CI and locally)
# Set ALLURE_DISABLED=true to disable Allure reporting
unless ENV["ALLURE_DISABLED"] == "true"
  require "allure-ruby-commons"
  require "securerandom"
  # Use TEST_ENV_NUMBER for parallel execution support
  allure_results_dir = "allure-results#{ENV["TEST_ENV_NUMBER"] || ""}"
  Allure.configure do |config|
    config.results_directory = allure_results_dir
    config.clean_results_directory = false
  end

  # Add Minitest plugin for Allure
  begin
    require "allure-ruby-commons/rspec"
  rescue LoadError
    # RSpec adapter not available, skip
  end
  begin
    require "allure-ruby-commons/cucumber"
  rescue LoadError
    # Cucumber adapter not available, skip
  end

  # Start a single global test container for all tests
  container = Allure::TestResultContainer.new(uuid: SecureRandom.uuid)
  Allure.lifecycle.start_test_container(container)

  # Minitest integration for Allure
  module AllureMinitestPlugin
    def before_setup
      super

      test_name = "#{self.class.name}##{name}"
      result = Allure::TestResult.new(
        name: test_name,
        full_name: test_name
      )
      Allure.lifecycle.start_test_case(result)
    end

    def after_teardown
      # Only update/stop if test case was started successfully
      begin
        status = if passed?
          Allure::Status::PASSED
        elsif skipped?
          Allure::Status::SKIPPED
        else
          Allure::Status::FAILED
        end

        Allure.lifecycle.update_test_case { |test_case| test_case.status = status }
        Allure.lifecycle.stop_test_case
      rescue
        # Silently handle errors if test case wasn't started
        # This can happen if before_setup failed or container wasn't started
      end

      super
    end
  end

  # Stop all test containers when process exits
  at_exit do
    Allure.lifecycle.stop_test_container
  rescue
    # Ignore errors when stopping container
  end

  ActiveSupport::TestCase.include(AllureMinitestPlugin)
end

reporters = []

if ENV["BT_TEST_FORMAT"]&.downcase == "dots"
  # The classic "dot style" output:
  # ...S..E...F...
  reporters.push Minitest::Reporters::DefaultReporter.new
else
  # "Spec style" output that shows you which tests are executing as they run:
  # UserTest
  #   test_details_provided_should_be_true_when_details_are_provided  PASS (0.18s)
  reporters.push Minitest::Reporters::SpecReporter.new(print_failure_summary: true)
end

# This reporter generates XML documents into test/reports that are used by CI services to tally results.
# We add it last because doing so make the visible test output a little cleaner.
reporters.push Minitest::Reporters::JUnitReporter.new if ENV["CI"]

Minitest::Reporters.use! reporters

require "parallel_tests/test/runtime_logger" if ENV["PARALLEL_TESTS_RECORD_RUNTIME"]

begin
  require "bullet_train/billing/test_support"
  FactoryBot.definition_file_paths << BulletTrain::Billing::TestSupport::FACTORY_PATH
  FactoryBot.reload
rescue LoadError
end

begin
  require "bullet_train/billing/stripe/test_support"
  FactoryBot.definition_file_paths << BulletTrain::Billing::Stripe::TestSupport::FACTORY_PATH
  FactoryBot.reload
rescue LoadError
end

ActiveSupport::TestCase.class_eval do
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
