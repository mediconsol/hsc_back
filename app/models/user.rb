class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  
  enum :role, { read_only: 0, staff: 1, manager: 2, admin: 3 }
  
  def generate_jwt_token
    payload = {
      user_id: id,
      email: email,
      role: role,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
  
  def self.decode_jwt_token(token)
    decoded = JWT.decode(token, Rails.application.secret_key_base).first
    find(decoded['user_id'])
  rescue JWT::DecodeError
    nil
  end
end