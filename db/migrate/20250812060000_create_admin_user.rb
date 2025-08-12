class CreateAdminUser < ActiveRecord::Migration[8.0]
  def up
    # ActiveRecord 방식으로 안전하게 생성
    say "Creating admin user: admin@mediconsol.com"
    
    # 이미 존재하는지 확인
    if connection.select_value("SELECT COUNT(*) FROM users WHERE email = 'admin@mediconsol.com'").to_i > 0
      say "Admin user already exists, skipping..."
      return
    end

    # 비밀번호 해시 생성 (bcrypt)
    require 'bcrypt'
    password_digest = BCrypt::Password.create('test1234')

    # 사용자 생성
    connection.execute(<<~SQL)
      INSERT INTO users (email, password_digest, role, name, created_at, updated_at)
      VALUES ('admin@mediconsol.com', '#{connection.quote(password_digest)}', 3, '시스템 관리자', NOW(), NOW())
    SQL

    say "✅ 관리자 계정 생성 완료: admin@mediconsol.com"
  end

  def down
    connection.execute("DELETE FROM users WHERE email = 'admin@mediconsol.com'")
  end
end