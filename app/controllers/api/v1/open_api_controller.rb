class Api::V1::OpenApiController < ApplicationController
  def index
    render file: Rails.root.join("app/views/api/v1/open_api/index.yaml.erb"),
      content_type: "application/x-yaml"
  end
end
