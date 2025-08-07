# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Hospital Management System API V1',
        version: 'v1',
        description: '병원 통합 관리 시스템 REST API 문서'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:7001',
          description: 'Development server'
        },
        {
          url: 'https://api.hospital.com',
          description: 'Production server'
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: 'JWT 토큰을 Authorization 헤더에 포함하세요. 예) Authorization: Bearer YOUR_TOKEN'
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            properties: {
              status: { type: :string, example: 'error' },
              message: { type: :string, example: '오류가 발생했습니다.' },
              timestamp: { type: :string, format: 'date-time' },
              request_id: { type: :string, format: :uuid }
            }
          },
          ValidationErrorResponse: {
            type: :object,
            properties: {
              status: { type: :string, example: 'error' },
              message: { type: :string, example: '입력 데이터에 오류가 있습니다.' },
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                }
              },
              timestamp: { type: :string, format: 'date-time' },
              request_id: { type: :string, format: :uuid }
            }
          },
          Pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              per_page: { type: :integer, example: 20 },
              total_pages: { type: :integer, example: 10 },
              total_count: { type: :integer, example: 200 },
              has_next_page: { type: :boolean, example: true },
              has_prev_page: { type: :boolean, example: false }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml
end