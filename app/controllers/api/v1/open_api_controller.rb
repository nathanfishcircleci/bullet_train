class Api::V1::OpenApiController < ApplicationController
  def index
    openapi_doc = {
      openapi: "3.1.0",
      info: {
        title: "Bullet Train API",
        description: "API for Bullet Train application",
        version: "1.0.0"
      },
      servers: [
        {
          url: "#{request.base_url}/api/v1"
        }
      ],
      paths: {
        "/": {
          get: {
            summary: "API Root",
            responses: {
              "200": {
                description: "Success"
              }
            }
          }
        }
      }
    }
    
    render plain: openapi_doc.to_yaml, content_type: "application/x-yaml"
  end
end
