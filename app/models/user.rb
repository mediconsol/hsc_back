class User < ApplicationRecord
  has_secure_password
  
  # 대화 기록과의 관계
  has_many :conversation_histories, dependent: :destroy
  
  # 시설/자산 관리와의 관계
  has_many :managed_facilities, class_name: 'Facility', foreign_key: 'manager_id', dependent: :nullify
  has_many :managed_assets, class_name: 'Asset', foreign_key: 'manager_id', dependent: :nullify

  validates :email, presence: true, 
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "올바른 이메일 형식이 아닙니다" }
  
  validates :name, presence: true, 
            length: { minimum: 2, maximum: 50 },
            format: { with: /\A[가-힣a-zA-Z\s]+\z/, message: "한글, 영문, 공백만 입력 가능합니다" }
  
  validates :password, length: { minimum: 8 }, if: :password_required?
  
  enum :role, { read_only: 0, staff: 1, manager: 2, admin: 3 }
  
  def generate_jwt_token
    expiration_hours = ENV.fetch("JWT_EXPIRATION_HOURS", "2").to_i
    payload = {
      user_id: id,
      email: email,
      role: role,
      name: name,
      iat: Time.current.to_i,
      exp: expiration_hours.hours.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def generate_refresh_token
    payload = {
      user_id: id,
      type: 'refresh',
      iat: Time.current.to_i,
      exp: 7.days.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end
  
  def self.decode_jwt_token(token)
    decoded = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' }).first
    return nil if decoded['type'] == 'refresh' # 리프레시 토큰으로는 인증 불가
    find(decoded['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end
  
  def self.decode_refresh_token(token)
    decoded = JWT.decode(token, jwt_secret_key, true, { algorithm: 'HS256' }).first
    return nil unless decoded['type'] == 'refresh' # 리프레시 토큰만 허용
    find(decoded['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.warn "JWT refresh token decode error: #{e.message}"
    nil
  end
  
  private
  
  def self.jwt_secret_key
    ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
  end
  
  def jwt_secret_key
    self.class.jwt_secret_key
  end
  
  def password_required?
    password.present? || password_confirmation.present?
  end
end