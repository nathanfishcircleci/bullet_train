require "controllers/api/v1/test"
require "fileutils"

class Api::OpenApiControllerTest < Api::Test
  setup do
    Rails.application.eager_load!
  end

  test "OpenAPI document is valid" do
    skip
  end

  test "OpenAPI document returns YAML content" do
    skip
  end

  test "OpenAPI document includes server information" do
    skip
  end

  test "OpenAPI document includes paths" do
    skip
  end
end
