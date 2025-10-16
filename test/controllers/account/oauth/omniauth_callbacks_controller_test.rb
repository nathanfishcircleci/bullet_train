require "test_helper"

class Account::Oauth::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:user)
    @team = FactoryBot.create(:team)
  end

  test "stripe_connect callback" do
    # Mock the OAuth callback for Stripe
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:stripe_connect] = OmniAuth::AuthHash.new({
      provider: "stripe_connect",
      uid: "acct_test123",
      info: {
        name: "Test Account",
        email: "test@example.com"
      },
      credentials: {
        token: "sk_test_123",
        refresh_token: "rt_test_123"
      }
    })

    # Test the callback method
    get "/users/auth/stripe_connect/callback"

    # Should redirect or handle the callback appropriately
    assert_response :redirect
  end

  test "stripe_connect callback with team_id from env" do
    # Test with team_id in environment
    ENV["TEAM_ID"] = @team.id.to_s

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:stripe_connect] = OmniAuth::AuthHash.new({
      provider: "stripe_connect",
      uid: "acct_test123",
      info: {
        name: "Test Account",
        email: "test@example.com"
      }
    })

    get "/users/auth/stripe_connect/callback"

    assert_response :redirect
  ensure
    ENV.delete("TEAM_ID")
  end
end
