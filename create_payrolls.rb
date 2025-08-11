#!/usr/bin/env ruby
require_relative 'config/environment'

# 2025년 1월 급여 데이터 생성
jan_2025_start = Date.new(2025, 1, 1)
jan_2025_end = Date.new(2025, 1, 31)

Employee.active.each do |employee|
  next if employee.name == '김휴직자'
  
  # 기본급 설정
  base_pay = employee.base_salary || 0
  
  # 부서별 수당
  allowances = case employee.department
  when '의료진' then rand(200000..500000)
  when '간호부' then rand(100000..300000)  
  when '행정부' then rand(50000..150000)
  when '시설관리' then rand(30000..100000)
  else 0
  end
  
  overtime_pay = rand(0..400000)
  night_pay = rand(0..250000) 
  deductions = (base_pay * 0.05).round # 5% 공제
  tax = ((base_pay + allowances + overtime_pay + night_pay) * 0.08).round # 8% 세금
  
  # net_pay 계산
  gross_pay = base_pay + overtime_pay + night_pay + allowances
  net_pay = gross_pay - deductions - tax
  
  payroll = Payroll.create!(
    employee: employee,
    pay_period_start: jan_2025_start,
    pay_period_end: jan_2025_end,
    base_pay: base_pay,
    overtime_pay: overtime_pay,
    night_pay: night_pay,
    allowances: allowances,
    deductions: deductions,
    tax: tax,
    net_pay: net_pay,
    status: 'approved'
  )
  
  puts "Created payroll for #{employee.name}: #{payroll.net_pay.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')}원"
end

total = Payroll.where(pay_period_start: jan_2025_start).sum(:net_pay)
puts "\nTotal payroll for January 2025: #{total.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')}원"
puts "Number of payrolls created: #{Payroll.where(pay_period_start: jan_2025_start).count}"