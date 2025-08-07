# Factory for Employee model
FactoryBot.define do
  factory :employee do
    name { Faker::Name.name }
    department { %w[의료진 간호부 행정부 시설관리].sample }
    position { Faker::Job.title }
    employment_type { %w[full_time contract part_time intern].sample }
    hire_date { Faker::Date.between(from: 5.years.ago, to: Date.current) }
    phone { "010-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
    email { Faker::Internet.email }
    base_salary { Faker::Number.between(from: 2_000_000, to: 8_000_000) }
    salary_type { 'monthly' }
    status { 'active' }
    
    trait :doctor do
      department { '의료진' }
      position { '의사' }
      base_salary { Faker::Number.between(from: 6_000_000, to: 12_000_000) }
    end
    
    trait :nurse do
      department { '간호부' }
      position { '간호사' }
      base_salary { Faker::Number.between(from: 3_500_000, to: 5_500_000) }
    end
    
    trait :admin_staff do
      department { '행정부' }
      position { '행정직원' }
      base_salary { Faker::Number.between(from: 2_500_000, to: 4_500_000) }
    end
    
    trait :facility_staff do
      department { '시설관리' }
      position { '시설관리직' }
      base_salary { Faker::Number.between(from: 2_000_000, to: 3_500_000) }
    end
    
    trait :contract do
      employment_type { 'contract' }
    end
    
    trait :part_time do
      employment_type { 'part_time' }
      salary_type { 'hourly' }
      base_salary { nil }
      hourly_rate { Faker::Number.between(from: 15_000, to: 25_000) }
    end
    
    trait :on_leave do
      status { 'on_leave' }
    end
    
    trait :inactive do
      status { 'inactive' }
    end
  end
end