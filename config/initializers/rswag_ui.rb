# Rswag UI configuration (limit to non-production to avoid boot issues)
if (Rails.env.development? || Rails.env.test?) && defined?(Rswag) && defined?(Rswag::Ui)
  Rswag::Ui.configure do |c|
  # List the Swagger endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path (absolute or relative to host) to the corresponding
  # endpoint and the second is a title that will be displayed in the document selector
  # NOTE: If you're using rspec-api to expose Swagger files (under swagger_root) as JSON or YAML endpoints,
  # then the list below should correspond to the relative paths for those endpoints

  c.swagger_endpoint '/api-docs/v1/swagger.yaml', 'Hospital Management System API V1'
  
  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'admin', 'password'
  
  # If you want to display the request headers in the swagger-ui
  c.config_object = {
    deepLinking: true,
    displayOperationId: false,
    defaultModelsExpandDepth: 1,
    defaultModelExpandDepth: 1,
    defaultModelRendering: 'example',
    displayRequestDuration: true,
    docExpansion: 'none',
    filter: true,
    maxDisplayedTags: -1,
    showExtensions: true,
    showCommonExtensions: true
  }
  end
end