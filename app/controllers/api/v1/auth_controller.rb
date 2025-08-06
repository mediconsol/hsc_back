class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:login, :refresh]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      access_token = user.generate_jwt_token
      refresh_token = user.generate_refresh_token
      
      render json: {
        status: 'success',
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: ENV.fetch("JWT_EXPIRATION_HOURS", "2").to_i * 3600, # 초 단위
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      }
    else
      render json: { 
        status: 'error', 
        message: 'Invalid credentials' 
      }, status: :unauthorized
    end
  end
  
  def refresh
    refresh_token = params[:refresh_token]
    
    if refresh_token.blank?
      return render json: { 
        status: 'error', 
        message: 'Refresh token is required' 
      }, status: :bad_request
    end
    
    user = User.decode_refresh_token(refresh_token)
    
    if user
      new_access_token = user.generate_jwt_token
      new_refresh_token = user.generate_refresh_token
      
      render json: {
        status: 'success',
        access_token: new_access_token,
        refresh_token: new_refresh_token,
        expires_in: ENV.fetch("JWT_EXPIRATION_HOURS", "2").to_i * 3600
      }
    else
      render json: { 
        status: 'error', 
        message: 'Invalid or expired refresh token' 
      }, status: :unauthorized
    end
  end
  
  def logout
    # 여기서 실제로는 토큰을 블랙리스트에 추가하는 것이 좋지만
    # 현재는 클라이언트 측에서 토큰을 삭제하도록 함
    render json: { 
      status: 'success', 
      message: 'Logged out successfully' 
    }
  end
  
  def me
    render json: {
      status: 'success',
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        role: current_user.role
      }
    }
  end
end