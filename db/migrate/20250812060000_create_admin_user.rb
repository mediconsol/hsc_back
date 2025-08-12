class CreateAdminUser < ActiveRecord::Migration[8.0]
  def up
    # 관리자 사용자 생성 (안전한 방식)
    return if connection.execute("SELECT COUNT(*) FROM users WHERE email = 'admin@mediconsol.com'").first[0] > 0

    # 비밀번호 해시 생성 (bcrypt)
    require 'bcrypt'
    password_digest = BCrypt::Password.create('test1234')

    connection.execute(<<~SQL)
      INSERT INTO users (email, password_digest, role, name, created_at, updated_at)
      VALUES ('admin@mediconsol.com', '#{password_digest}', 3, '시스템 관리자', NOW(), NOW())
    SQL

    puts "✅ 관리자 계정 생성 완료: admin@mediconsol.com"
  end

  def down
    connection.execute("DELETE FROM users WHERE email = 'admin@mediconsol.com'")
  end
end