# 프로덕션 전용 최소 시드 데이터
puts "🚀 프로덕션 환경 최소 시드 데이터 생성 중..."

# 기본 관리자 계정만 생성
admin = User.find_or_create_by!(email: 'admin@hospital.com') do |user|
  user.name = 'Hospital Admin'
  user.password = 'password123'
  user.role = 3 # admin
end

mediconsol_admin = User.find_or_create_by!(email: 'admin@mediconsol.com') do |user|
  user.name = '시스템 관리자'
  user.password = 'test1234'
  user.role = 3 # admin
end

manager = User.find_or_create_by!(email: 'manager@hospital.com') do |user|
  user.name = '부서 관리자'
  user.password = 'password123'
  user.role = 2 # manager
end

staff = User.find_or_create_by!(email: 'staff@hospital.com') do |user|
  user.name = '병원 직원'
  user.password = 'password123'
  user.role = 1 # staff
end

puts "✅ 기본 사용자 4명 생성 완료"
puts "- admin@hospital.com / password123 (admin)"
puts "- admin@mediconsol.com / test1234 (admin)"  
puts "- manager@hospital.com / password123 (manager)"
puts "- staff@hospital.com / password123 (staff)"

puts "\n🎯 프로덕션 시드 데이터 생성 완료 - 메모리 사용량 최소화"