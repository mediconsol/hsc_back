# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
admin = User.find_or_create_by!(email: 'admin@hospital.com') do |user|
  user.name = 'Hospital Admin'
  user.password = 'password123'
  user.role = 'admin'
end

# Create new admin user for mediconsol
mediconsol_admin = User.find_or_create_by!(email: 'admin@mediconsol.com') do |user|
  user.name = '시스템 관리자'
  user.password = 'test1234'
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
puts "Mediconsol Admin: admin@mediconsol.com / test1234"
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

# Create sample payrolls
if Employee.exists?
  active_employees = Employee.active
  
  # 2024년 12월 급여 데이터
  dec_2024_start = Date.new(2024, 12, 1)
  dec_2024_end = Date.new(2024, 12, 31)
  
  # 2025년 1월 급여 데이터
  jan_2025_start = Date.new(2025, 1, 1)
  jan_2025_end = Date.new(2025, 1, 31)
  
  active_employees.each do |employee|
    next if employee.name == '김휴직자' # 휴직자는 제외
    
    # 기본급 설정
    base_pay = employee.base_salary || 0
    
    # 부서별 수당 및 공제액 계산
    allowances = case employee.department
    when '의료진' then rand(200000..500000)
    when '간호부' then rand(100000..300000)
    when '행정부' then rand(50000..150000)
    when '시설관리' then rand(30000..100000)
    else 0
    end
    
    overtime_pay = rand(0..300000)
    night_pay = rand(0..200000)
    deductions = (base_pay * 0.05).round # 5% 공제
    tax = ((base_pay + allowances + overtime_pay + night_pay) * 0.08).round # 8% 세금
    
    # 2024년 12월 급여
    Payroll.find_or_create_by(
      employee: employee,
      pay_period_start: dec_2024_start,
      pay_period_end: dec_2024_end
    ) do |payroll|
      payroll.base_pay = base_pay
      payroll.overtime_pay = overtime_pay
      payroll.night_pay = night_pay
      payroll.allowances = allowances
      payroll.deductions = deductions
      payroll.tax = tax
      payroll.status = 'paid'
    end
    
    # 2025년 1월 급여 (현재 월)
    jan_overtime = rand(0..400000)
    jan_night = rand(0..250000)
    jan_deductions = (base_pay * 0.05).round
    jan_tax = ((base_pay + allowances + jan_overtime + jan_night) * 0.08).round
    
    Payroll.find_or_create_by(
      employee: employee,
      pay_period_start: jan_2025_start,
      pay_period_end: jan_2025_end
    ) do |payroll|
      payroll.base_pay = base_pay
      payroll.overtime_pay = jan_overtime
      payroll.night_pay = jan_night
      payroll.allowances = allowances
      payroll.deductions = jan_deductions
      payroll.tax = jan_tax
      payroll.status = 'approved'
    end
  end
  
  puts "\nCreated sample payrolls:"
  puts "December 2024 payrolls: #{Payroll.where(pay_period_start: dec_2024_start).count}"
  puts "January 2025 payrolls: #{Payroll.where(pay_period_start: jan_2025_start).count}"
  
  # 총 급여 현황
  jan_total = Payroll.where(pay_period_start: jan_2025_start).sum(:net_pay)
  puts "January 2025 total payroll: #{jan_total.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')}원"
end

# Create sample patients and appointments
sample_patients_data = [
  {
    name: '홍길동',
    birth_date: Date.new(1985, 3, 15),
    gender: 'male',
    phone: '010-1111-2222',
    email: 'hong@email.com',
    insurance_type: 'national',
    address: '서울시 강남구 테헤란로 123',
    status: 'active'
  },
  {
    name: '김영희',
    birth_date: Date.new(1992, 7, 22),
    gender: 'female',
    phone: '010-3333-4444',
    email: 'kim@email.com',
    insurance_type: 'employee',
    address: '서울시 서초구 서초대로 456',
    status: 'active'
  },
  {
    name: '박철수',
    birth_date: Date.new(1978, 11, 5),
    gender: 'male',
    phone: '010-5555-6666',
    email: 'park@email.com',
    insurance_type: 'national',
    address: '서울시 송파구 올림픽로 789',
    status: 'active'
  },
  {
    name: '이순이',
    birth_date: Date.new(1960, 2, 18),
    gender: 'female',
    phone: '010-7777-8888',
    email: 'lee@email.com',
    insurance_type: 'medical_aid',
    address: '서울시 영등포구 여의도대로 321',
    status: 'active'
  },
  {
    name: '최민수',
    birth_date: Date.new(1995, 9, 30),
    gender: 'male',
    phone: '010-9999-0000',
    email: 'choi@email.com',
    insurance_type: 'private',
    address: '서울시 마포구 홍대로 654',
    status: 'active'
  }
]

sample_patients_data.each do |patient_data|
  Patient.find_or_create_by(phone: patient_data[:phone]) do |patient|
    patient.name = patient_data[:name]
    patient.birth_date = patient_data[:birth_date]
    patient.gender = patient_data[:gender]
    patient.email = patient_data[:email]
    patient.insurance_type = patient_data[:insurance_type]
    patient.address = patient_data[:address]
    patient.status = patient_data[:status]
  end
end

if Patient.exists? && Employee.exists?
  patients = Patient.all
  doctors = Employee.where(department: '의료진')
  
  # 오늘과 내일 예약들
  sample_appointments_data = [
    {
      patient: patients.find_by(name: '홍길동'),
      employee: doctors.find_by(name: '김의사'),
      appointment_date: Date.current + 1.day + 9.hours,
      appointment_type: 'consultation',
      department: '의료진',
      chief_complaint: '감기 증상으로 인한 진료 희망',
      status: 'confirmed',
      created_by_patient: false
    },
    {
      patient: patients.find_by(name: '김영희'),
      employee: doctors.find_by(name: '이전문의'),
      appointment_date: Date.current + 2.days + 14.hours,
      appointment_type: 'checkup',
      department: '의료진',
      chief_complaint: '정기 건강검진을 받고 싶습니다',
      status: 'confirmed',
      created_by_patient: false
    },
    {
      patient: patients.find_by(name: '박철수'),
      employee: nil,
      appointment_date: Date.current + 3.days + 10.hours + 30.minutes,
      appointment_type: 'treatment',
      department: '의료진',
      chief_complaint: '허리 통증이 계속되어 치료가 필요합니다',
      status: 'pending',
      created_by_patient: true
    },
    {
      patient: patients.find_by(name: '이순이'),
      employee: doctors.find_by(name: '김의사'),
      appointment_date: Date.current.beginning_of_day + 13.hours,
      appointment_type: 'follow_up',
      department: '의료진',
      chief_complaint: '지난번 검사 결과 상담',
      status: 'confirmed',
      created_by_patient: false
    },
    {
      patient: patients.find_by(name: '최민수'),
      employee: nil,
      appointment_date: Date.current + 1.week + 15.hours,
      appointment_type: 'vaccination',
      department: '의료진',
      chief_complaint: '독감 예방접종 희망',
      status: 'pending',
      created_by_patient: true
    }
  ]
  
  sample_appointments_data.each do |appointment_data|
    next unless appointment_data[:patient]
    
    Appointment.find_or_create_by(
      patient: appointment_data[:patient],
      appointment_date: appointment_data[:appointment_date]
    ) do |appointment|
      appointment.employee = appointment_data[:employee]
      appointment.appointment_type = appointment_data[:appointment_type]
      appointment.department = appointment_data[:department]
      appointment.chief_complaint = appointment_data[:chief_complaint]
      appointment.status = appointment_data[:status]
      appointment.created_by_patient = appointment_data[:created_by_patient]
    end
  end
end

puts "\nCreated sample employees:"
puts "Total employees: #{Employee.count}"
puts "Active employees: #{Employee.active.count}"
puts "On leave: #{Employee.where(status: 'on_leave').count}"
puts "Pending leave requests: #{LeaveRequest.where(status: 'pending').count}"

puts "\nCreated sample patients and appointments:"
puts "Total patients: #{Patient.count}"
puts "Active patients: #{Patient.active.count}"
puts "Total appointments: #{Appointment.count}"
puts "Pending appointments: #{Appointment.pending.count}"
puts "Confirmed appointments: #{Appointment.confirmed.count}"
puts "Online requests: #{Appointment.online_requests.count}"

# Load finance-related seed data
puts "\n" + "="*50
puts "Loading Finance System Seeds..."
puts "="*50
# 환경별 시드 데이터 로딩
if Rails.env.production?
  # 프로덕션: 최소 데이터만
  load Rails.root.join('db', 'seeds', 'production_seeds.rb')
else
  # 개발/테스트: 전체 데이터
  load Rails.root.join('db', 'seeds', 'finance_seeds.rb')
end
