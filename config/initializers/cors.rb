# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 환경변수에서 허용된 origins 가져오기
    frontend_urls = ENV.fetch("FRONTEND_URL", "http://localhost:7002").split(",").map(&:strip)
    
    # Production에서는 Railway 도메인 추가
    if Rails.env.production?
      production_origins = [
        'https://hsc1-production-acea.up.railway.app',
        'https://hsc1-production.up.railway.app',
        'http://localhost:7002',
        'http://localhost:3000'
      ]
      origins production_origins + frontend_urls
    else
      origins frontend_urls
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['access-token', 'expiry', 'token-type', 'Authorization']
  end
end
