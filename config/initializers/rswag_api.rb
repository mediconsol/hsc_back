# Rswag API configuration
Rswag::Api.configure do |c|
  # Specify a root folder where Swagger JSON files are located
  c.swagger_root = Rails.root.join('swagger').to_s

  # Inject a lambda function to alter the returned Swagger prior to serialization
  # The function will have access to the rack env for the current request
  # For example, you could leverage this to dynamically assign the "host" property
  c.swagger_filter = lambda do |swagger, env|
    swagger['host'] = env['HTTP_HOST']
    swagger['schemes'] = env['rack.url_scheme'] == 'https' ? ['https'] : ['http']
    swagger['basePath'] = '/api/v1'
  end
end