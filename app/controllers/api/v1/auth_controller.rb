class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:login]
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = user.generate_jwt_token
      render json: {
        status: 'success',
        token: token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      }
    else
      render json: { status: 'error', message: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  def logout
    render json: { status: 'success', message: 'Logged out successfully' }
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