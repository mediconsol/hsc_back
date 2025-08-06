# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
admin = User.find_or_create_by!(email: 'admin@hospital.com') do |user|
  user.name = 'Hospital Admin'
  user.password = 'password123'
  user.role = 'admin'
end

# Create manager user
manager = User.find_or_create_by!(email: 'manager@hospital.com') do |user|
  user.name = 'Hospital Manager'
  user.password = 'password123'
  user.role = 'manager'
end

# Create staff user
staff = User.find_or_create_by!(email: 'staff@hospital.com') do |user|
  user.name = 'Hospital Staff'
  user.password = 'password123'
  user.role = 'staff'
end

puts "Created users:"
puts "Admin: admin@hospital.com / password123"
puts "Manager: manager@hospital.com / password123"
puts "Staff: staff@hospital.com / password123"

# Create sample employees
employees_data = [
  # 의료진
  {
    name: '김의사',
    department: '의료진',
    position: '과장',
    employment_type: 'full_time',
    hire_date: '2020-03-15',
    phone: '010-1234-5678',
    email: 'kim.doctor@hospital.com',
    base_salary: 5000000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '이전문의',
    department: '의료진',
    position: '전문의',
    employment_type: 'full_time',
    hire_date: '2021-06-01',
    phone: '010-2345-6789',
    email: 'lee.specialist@hospital.com',
    base_salary: 4500000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '박인턴',
    department: '의료진',
    position: '인턴',
    employment_type: 'intern',
    hire_date: '2024-03-01',
    phone: '010-3456-7890',
    email: 'park.intern@hospital.com',
    base_salary: 2500000,
    salary_type: 'monthly',
    status: 'active'
  },
  
  # 간호부
  {
    name: '최수간호사',
    department: '간호부',
    position: '수간호사',
    employment_type: 'full_time',
    hire_date: '2018-02-20',
    phone: '010-4567-8901',
    email: 'choi.head.nurse@hospital.com',
    base_salary: 3800000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '정간호사',
    department: '간호부',
    position: '간호사',
    employment_type: 'full_time',
    hire_date: '2022-05-10',
    phone: '010-5678-9012',
    email: 'jung.nurse@hospital.com',
    base_salary: 3200000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '한간호조무사',
    department: '간호부',
    position: '간호조무사',
    employment_type: 'contract',
    hire_date: '2023-08-15',
    phone: '010-6789-0123',
    email: 'han.assistant@hospital.com',
    base_salary: 2800000,
    salary_type: 'monthly',
    status: 'active'
  },
  
  # 행정부
  {
    name: '강행정팀장',
    department: '행정부',
    position: '팀장',
    employment_type: 'full_time',
    hire_date: '2019-01-10',
    phone: '010-7890-1234',
    email: 'kang.admin@hospital.com',
    base_salary: 4200000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '윤원무과',
    department: '행정부',
    position: '원무과',
    employment_type: 'full_time',
    hire_date: '2021-11-25',
    phone: '010-8901-2345',
    email: 'yoon.admin@hospital.com',
    base_salary: 3000000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '송파트타임',
    department: '행정부',
    position: '사무보조',
    employment_type: 'part_time',
    hire_date: '2024-01-08',
    phone: '010-9012-3456',
    email: 'song.parttime@hospital.com',
    hourly_rate: 15000,
    salary_type: 'hourly',
    status: 'active'
  },
  
  # 시설관리
  {
    name: '임관리팀장',
    department: '시설관리',
    position: '팀장',
    employment_type: 'full_time',
    hire_date: '2017-09-05',
    phone: '010-0123-4567',
    email: 'lim.facility@hospital.com',
    base_salary: 3500000,
    salary_type: 'monthly',
    status: 'active'
  },
  {
    name: '조보안요원',
    department: '시설관리',
    position: '보안요원',
    employment_type: 'contract',
    hire_date: '2023-04-12',
    phone: '010-1234-5670',
    email: 'cho.security@hospital.com',
    base_salary: 2600000,
    salary_type: 'monthly',
    status: 'active'
  },
  
  # 휴직/퇴사자 (통계용)
  {
    name: '김휴직자',
    department: '간호부',
    position: '간호사',
    employment_type: 'full_time',
    hire_date: '2020-07-01',
    phone: '010-2222-3333',
    email: 'kim.onleave@hospital.com',
    base_salary: 3200000,
    salary_type: 'monthly',
    status: 'on_leave'
  }
]

employees_data.each do |emp_data|
  Employee.find_or_create_by(email: emp_data[:email]) do |employee|
    employee.name = emp_data[:name]
    employee.department = emp_data[:department]
    employee.position = emp_data[:position]
    employee.employment_type = emp_data[:employment_type]
    employee.hire_date = Date.parse(emp_data[:hire_date])
    employee.phone = emp_data[:phone]
    employee.base_salary = emp_data[:base_salary] if emp_data[:base_salary]
    employee.hourly_rate = emp_data[:hourly_rate] if emp_data[:hourly_rate]
    employee.salary_type = emp_data[:salary_type]
    employee.status = emp_data[:status]
  end
end

# Create sample leave requests
if Employee.exists?
  employees = Employee.active
  
  # 현재 날짜 기준으로 휴가 신청 생성
  leave_requests_data = [
    {
      employee: employees.find_by(name: '정간호사'),
      leave_type: 'annual',
      start_date: Date.current + 5.days,
      end_date: Date.current + 6.days,
      days_requested: 2,
      reason: '개인 사정',
      status: 'pending'
    },
    {
      employee: employees.find_by(name: '박인턴'),
      leave_type: 'sick',
      start_date: Date.current - 2.days,
      end_date: Date.current - 2.days,
      days_requested: 1,
      reason: '몸살감기',
      status: 'approved'
    },
    {
      employee: employees.find_by(name: '송파트타임'),
      leave_type: 'personal',
      start_date: Date.current + 10.days,
      end_date: Date.current + 11.days,
      days_requested: 2,
      reason: '가족 행사',
      status: 'pending'
    },
    {
      employee: employees.find_by(name: '한간호조무사'),
      leave_type: 'annual',
      start_date: Date.current - 30.days,
      end_date: Date.current - 28.days,
      days_requested: 3,
      reason: '휴식',
      status: 'approved'
    }
  ]
  
  leave_requests_data.each do |lr_data|
    if lr_data[:employee]
      LeaveRequest.find_or_create_by(
        employee: lr_data[:employee],
        start_date: lr_data[:start_date],
        end_date: lr_data[:end_date]
      ) do |leave_request|
        leave_request.leave_type = lr_data[:leave_type]
        leave_request.days_requested = lr_data[:days_requested]
        leave_request.reason = lr_data[:reason]
        leave_request.status = lr_data[:status]
      end
    end
  end
end

puts "\nCreated sample employees:"
puts "Total employees: #{Employee.count}"
puts "Active employees: #{Employee.active.count}"
puts "On leave: #{Employee.where(status: 'on_leave').count}"
puts "Pending leave requests: #{LeaveRequest.where(status: 'pending').count}"
