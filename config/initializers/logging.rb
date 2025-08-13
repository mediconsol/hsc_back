# Railway 환경 최적화 로깅 설정

if Rails.env.production?
  # Railway 로그 포맷 최적화
  Rails.application.config.log_formatter = Logger::Formatter.new
  
  # 로그 태그 최적화
  Rails.application.config.log_tags = [
    :request_id,
    -> request { "IP:#{request.remote_ip}" },
    -> request { "Method:#{request.method}" },
    -> request { "Path:#{request.path}" }
  ]

  # 성능 로깅
  Rails.application.config.active_record.logger = nil if ENV['DISABLE_DB_LOGS'] == 'true'

  # 커스텀 로거 설정
  class RailwayLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      {
        timestamp: timestamp.utc.iso8601,
        level: severity,
        service: 'hospital-backend',
        environment: Rails.env,
        message: msg,
        request_id: Thread.current[:request_id],
        railway_service: ENV['RAILWAY_SERVICE_NAME']
      }.compact.to_json + "\n"
    end
  end

  # Request ID 추적 (application.rb에서 설정)
  # class RequestIdMiddleware
  #   def initialize(app)
  #     @app = app
  #   end
  #
  #   def call(env)
  #     Thread.current[:request_id] = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
  #     @app.call(env)
  #   ensure
  #     Thread.current[:request_id] = nil
  #   end
  # end

  # 에러 추적 (Railway 로그에서 쉽게 필터링)
  Rails.application.config.exceptions_app = ->(env) {
    error_info = {
      error: 'Application Error',
      status: env['PATH_INFO'][1..-1].to_i,
      path: env['ORIGINAL_FULLPATH'],
      method: env['REQUEST_METHOD'],
      timestamp: Time.current.utc.iso8601
    }
    
    Rails.logger.error(error_info.to_json)
    
    [
      env['PATH_INFO'][1..-1].to_i,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Internal Server Error' }.to_json]
    ]
  }
end

# 개발 환경에서도 구조화 로깅 옵션
if Rails.env.development? && ENV['STRUCTURED_LOGS'] == 'true'
  Rails.logger = RailwayLogger.new(STDOUT)
end