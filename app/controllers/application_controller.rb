class ApplicationController < ActionController::API
  before_action :authenticate_request
  
  private
  
  def authenticate_request
    return if @skip_auth
    
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    if header
      @current_user = User.decode_jwt_token(header)
      render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
    else
      render json: { error: 'Missing token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def skip_authentication
    @skip_auth = true
  end
end
