require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Railway Redis 캐시 설정 (Redis 서비스 추가 시 활성화)
  if ENV["REDIS_URL"].present?
    config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
  else
    config.cache_store = :memory_store, { size: 64.megabytes }
  end

  # Active Job 설정 (비동기 작업용)
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  mailer_host = ENV["RAILWAY_PUBLIC_DOMAIN"] || ENV["RAILWAY_STATIC_URL"] || "localhost"
  config.action_mailer.default_url_options = { host: mailer_host, protocol: 'https' }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # Railway 도메인 허용 설정
  allowed_hosts = []
  allowed_hosts << ENV["RAILWAY_STATIC_URL"] if ENV["RAILWAY_STATIC_URL"].present?
  allowed_hosts << ENV["RAILWAY_PUBLIC_DOMAIN"] if ENV["RAILWAY_PUBLIC_DOMAIN"].present?
  allowed_hosts << /.*\.railway\.app$/
  
  config.hosts = allowed_hosts if allowed_hosts.any?
  
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Railway 최적화 설정
  # 보안 헤더 설정
  config.force_ssl = true
  config.ssl_options = { 
    redirect: { 
      exclude: ->(request) { 
        request.path == "/up" || request.path.start_with?("/rails/active_storage")
      } 
    } 
  }

  # Performance 최적화
  config.middleware.use Rack::Deflate
  
  # 세션 보안 강화
  config.session_store :cookie_store, 
    key: '_hospital_system_session',
    secure: true,
    httponly: true,
    same_site: :lax

  # CORS preflight 최적화
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=2592000',
    'Expires' => 30.days.from_now.to_formatted_s(:rfc822)
  }

  # Railway 로그 최적화
  if ENV["RAILWAY_ENVIRONMENT"].present?
    config.logger = ActiveSupport::TaggedLogging.new(
      Logger.new(STDOUT, 
        level: Logger.const_get(ENV.fetch("RAILS_LOG_LEVEL", "INFO").upcase),
        formatter: Logger::Formatter.new
      )
    )
  end

  # 데이터베이스 연결 최적화
  config.active_record.connection_db_config.configuration_hash.merge!(
    pool: ENV.fetch("RAILS_MAX_THREADS", 10).to_i,
    timeout: 5000,
    checkout_timeout: 5,
    reaping_frequency: 10
  ) if defined?(ActiveRecord)
end
