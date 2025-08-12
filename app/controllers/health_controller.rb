# Health check controller - 인증 없이 접근 가능
class HealthController < ActionController::API
  # 에러 발생 시 JSON 응답
  rescue_from Exception do |e|
    render json: { 
      error: e.class.name, 
      message: e.message,
      backtrace: e.backtrace.first(5)
    }, status: 500
  end

  # Railway 기본 Health Check
  def show
    render plain: "OK", status: :ok
  end

  # 상세 Health Check (모니터링용)
  def detailed
    start_time = Time.current
    
    health_status = {
      status: 'healthy',
      timestamp: start_time.utc.iso8601,
      service: 'hospital-backend',
      version: Rails.application.class.module_parent_name,
      environment: Rails.env,
      checks: {}
    }

    begin
      # 데이터베이스 연결 확인
      db_start = Time.current
      ActiveRecord::Base.connection.execute("SELECT 1")
      health_status[:checks][:database] = {
        status: 'healthy',
        response_time_ms: ((Time.current - db_start) * 1000).round(2)
      }
    rescue => e
      health_status[:status] = 'unhealthy'
      health_status[:checks][:database] = {
        status: 'unhealthy',
        error: e.message
      }
    end

    # Redis 연결 확인 (있는 경우)
    if ENV['REDIS_URL'].present?
      begin
        redis_start = Time.current
        # Redis 연결 테스트
        health_status[:checks][:redis] = {
          status: 'healthy',
          response_time_ms: ((Time.current - redis_start) * 1000).round(2)
        }
      rescue => e
        health_status[:checks][:redis] = {
          status: 'unhealthy',
          error: e.message
        }
      end
    end

    # 메모리 사용량 확인
    if defined?(GC)
      gc_stat = GC.stat
      health_status[:checks][:memory] = {
        status: 'healthy',
        heap_allocated_pages: gc_stat[:heap_allocated_pages],
        heap_live_slots: gc_stat[:heap_live_slots],
        total_allocated_objects: gc_stat[:total_allocated_objects]
      }
    end

    # 응답 시간 확인
    total_response_time = ((Time.current - start_time) * 1000).round(2)
    health_status[:response_time_ms] = total_response_time

    # 전체 상태 결정
    if health_status[:checks].any? { |_, check| check[:status] == 'unhealthy' }
      health_status[:status] = 'unhealthy'
      status_code = :service_unavailable
    else
      status_code = :ok
    end

    # Railway 환경에서 로깅
    if Rails.env.production?
      Rails.logger.info({
        event: 'health_check',
        status: health_status[:status],
        response_time_ms: total_response_time,
        checks: health_status[:checks].transform_values { |v| v[:status] }
      }.to_json)
    end

    render json: health_status, status: status_code
  end

  # 버전 정보
  def version
    version_info = {
      service: 'hospital-backend',
      version: '1.0.0',
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION,
      environment: Rails.env,
      deployment_time: ENV['RAILWAY_DEPLOYMENT_ID'] || 'unknown',
      git_commit: ENV['RAILWAY_GIT_COMMIT_SHA'] || 'unknown'
    }

    render json: version_info
  end

  # 데이터베이스 테이블 목록 확인 (임시 디버그용)
  def tables
    begin
      tables_list = ActiveRecord::Base.connection.tables.sort
      table_info = {
        status: 'success',
        tables_count: tables_list.count,
        tables: tables_list
      }
      
      # 주요 테이블들 확인
      expected_tables = %w[users employees patients announcements documents]
      missing_tables = expected_tables - tables_list
      
      table_info[:expected_tables_status] = {
        found: expected_tables & tables_list,
        missing: missing_tables
      }
      
      render json: table_info
    rescue => e
      render json: { 
        status: 'error', 
        error: e.message,
        tables_count: 0
      }, status: :service_unavailable
    end
  end

  # 강제 마이그레이션 실행 (임시 디버그용)
  def migrate
    begin
      Rails.logger.info "Starting manual database migration..."
      
      # 마이그레이션 실행
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
      
      # 시드 데이터 실행
      begin
        Rails.application.load_seed
        seed_status = "success"
      rescue => seed_error
        seed_status = "failed: #{seed_error.message}"
      end
      
      # 테이블 목록 확인
      tables_after = ActiveRecord::Base.connection.tables.sort
      
      render json: {
        status: "migration_completed",
        tables_created: tables_after.count,
        tables: tables_after,
        seed_status: seed_status,
        timestamp: Time.current.utc.iso8601
      }
      
    rescue => e
      render json: {
        status: "migration_failed",
        error: e.class.name,
        message: e.message,
        backtrace: e.backtrace.first(5)
      }, status: 500
    end
  end
end