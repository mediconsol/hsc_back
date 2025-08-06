class ApplicationController < ActionController::API
  before_action :authenticate_request
  
  # 공통 예외 처리
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from StandardError, with: :internal_server_error
  
  private
  
  def authenticate_request
    return if @skip_auth
    
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    if header
      @current_user = User.decode_jwt_token(header)
      unless @current_user
        render_error('인증에 실패했습니다. 다시 로그인해주세요.', :unauthorized)
      end
    else
      render_error('인증 토큰이 필요합니다.', :unauthorized)
    end
  end
  
  def current_user
    @current_user
  end
  
  def skip_authentication
    @skip_auth = true
  end
  
  # 공통 에러 응답 메서드
  def render_error(message, status = :bad_request, details = nil)
    error_response = {
      status: 'error',
      message: message,
      timestamp: Time.current.iso8601
    }
    
    error_response[:details] = details if details.present?
    error_response[:request_id] = request.uuid if request.respond_to?(:uuid)
    
    render json: error_response, status: status
  end
  
  def render_success(data = nil, message = nil)
    success_response = {
      status: 'success',
      timestamp: Time.current.iso8601
    }
    
    success_response[:message] = message if message.present?
    success_response[:data] = data if data.present?
    
    render json: success_response
  end
  
  # 예외 핸들러들
  def record_not_found(e)
    render_error('요청한 리소스를 찾을 수 없습니다.', :not_found)
  end
  
  def record_invalid(e)
    render_error('입력 데이터가 올바르지 않습니다.', :unprocessable_entity, e.record.errors.full_messages)
  end
  
  def parameter_missing(e)
    render_error("필수 파라미터가 누락되었습니다: #{e.param}", :bad_request)
  end
  
  def internal_server_error(e)
    Rails.logger.error "Internal Server Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    if Rails.env.development?
      render_error('서버 내부 오류가 발생했습니다.', :internal_server_error, e.message)
    else
      render_error('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.', :internal_server_error)
    end
  end
end
