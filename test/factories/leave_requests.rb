# Factory for LeaveRequest model
FactoryBot.define do
  factory :leave_request do
    association :employee
    association :approver, factory: [:user, :manager]
    
    leave_type { %w[annual sick personal bereavement].sample }
    start_date { Faker::Date.between(from: 1.week.from_now, to: 3.months.from_now) }
    end_date { start_date + rand(1..5).days }
    days_requested { (end_date - start_date).to_i + 1 }
    reason { Faker::Lorem.sentence }
    status { 'pending' }
    
    trait :annual do
      leave_type { 'annual' }
      reason { '연차 휴가' }
    end
    
    trait :sick do
      leave_type { 'sick' }
      reason { '병가' }
    end
    
    trait :personal do
      leave_type { 'personal' }
      reason { '개인 사정' }
    end
    
    trait :bereavement do
      leave_type { 'bereavement' }
      reason { '경조사' }
      days_requested { 3 }
    end
    
    trait :pending do
      status { 'pending' }
    end
    
    trait :approved do
      status { 'approved' }
      approved_at { Faker::Time.between(from: start_date - 1.week, to: start_date - 1.day) }
    end
    
    trait :rejected do
      status { 'rejected' }
      approved_at { Faker::Time.between(from: start_date - 1.week, to: start_date - 1.day) }
      admin_notes { '요청 기간 중 중요 업무가 있어 반려합니다.' }
    end
    
    trait :cancelled do
      status { 'cancelled' }
    end
    
    trait :short_leave do
      start_date { 1.week.from_now }
      end_date { 1.week.from_now }
      days_requested { 1 }
    end
    
    trait :long_leave do
      start_date { 2.weeks.from_now }
      end_date { 3.weeks.from_now }
      days_requested { 7 }
    end
    
    trait :past_leave do
      start_date { Faker::Date.between(from: 3.months.ago, to: 1.week.ago) }
      end_date { start_date + rand(1..3).days }
      status { 'approved' }
      approved_at { start_date - 1.week }
    end
  end
end