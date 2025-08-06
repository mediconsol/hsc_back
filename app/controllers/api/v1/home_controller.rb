class Api::V1::HomeController < ApplicationController
  skip_before_action :authenticate_request, only: [:index]
  
  def index
    render json: {
      message: "Hospital Management System API",
      version: "1.0.0",
      endpoints: {
        auth: {
          login: "POST /api/v1/auth/login",
          logout: "DELETE /api/v1/auth/logout", 
          me: "GET /api/v1/auth/me"
        }
      },
      status: "running",
      timestamp: Time.current
    }
  end
end