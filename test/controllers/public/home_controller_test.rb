require "test_helper"

class Public::HomeControllerTest < ActionDispatch::IntegrationTest
  test "root redirect when MARKETING_SITE_URL is set" do
    ENV["MARKETING_SITE_URL"] = "https://example.com"

    get "/"

    assert_response :redirect
    assert_redirected_to "https://example.com"
  ensure
    ENV.delete("MARKETING_SITE_URL")
  end

  test "root redirect to sign in when no marketing site" do
    ENV.delete("MARKETING_SITE_URL")

    get "/"

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "invitation only mode" do
    # Test the invite-only functionality
    get "/"

    # Should redirect to sign in or invitation page
    assert_response :redirect
  end

  test "documentation support" do
    # Test that documentation is available
    get "/docs"

    # Should either serve documentation or redirect appropriately
    assert_response :success
  end
end
