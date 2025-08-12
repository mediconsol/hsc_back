class CreateAdminUser < ActiveRecord::Migration[8.0]
  def up
    # 관리자 사용자 생성
    User.create!(
      email: 'admin@mediconsol.com',
      password: 'test1234',
      password_confirmation: 'test1234',
      role: 3, # admin role
      name: '시스템 관리자',
      confirmed_at: Time.current
    ) unless User.exists?(email: 'admin@mediconsol.com')
  end

  def down
    User.find_by(email: 'admin@mediconsol.com')&.destroy
  end
end