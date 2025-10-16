class Api::V1::OpenApiController < ApplicationController
  def index
    yaml_content = <<~YAML
      openapi: 3.1.0
      info:
        title: Bullet Train API
        description: API for Bullet Train application
        version: 1.0.0
      servers:
        - url: #{request.base_url}/api/v1
      paths:
        /:
          get:
            summary: API Root
            responses:
              '200':
                description: Success
    YAML
    
    render plain: yaml_content, content_type: "text/yaml"
  end
end
