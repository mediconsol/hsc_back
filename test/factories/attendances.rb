# Factory for Attendance model
FactoryBot.define do
  factory :attendance do
    association :employee
    
    work_date { Faker::Date.between(from: 1.month.ago, to: Date.current) }
    check_in { work_date.beginning_of_day + 8.hours + rand(-30..30).minutes }
    check_out { check_in + 8.hours + rand(0..4).hours }
    regular_hours { 8.0 }
    overtime_hours { [check_out - check_in - 8.hours, 0].max / 1.hour }
    status { 'present' }
    
    trait :present do
      status { 'present' }
    end
    
    trait :absent do
      status { 'absent' }
      check_in { nil }
      check_out { nil }
      regular_hours { 0 }
      overtime_hours { 0 }
    end
    
    trait :late do
      status { 'late' }
      check_in { work_date.beginning_of_day + 9.hours + rand(1..60).minutes }
    end
    
    trait :early_leave do
      status { 'early_leave' }
      check_out { check_in + rand(4..7).hours }
      regular_hours { (check_out - check_in) / 1.hour }
      overtime_hours { 0 }
    end
    
    trait :with_overtime do
      check_out { check_in + 10.hours + rand(0..4).hours }
      overtime_hours { (check_out - check_in - 8.hours) / 1.hour }
    end
    
    trait :weekend do
      work_date { Date.current.beginning_of_week + rand(5..6).days }
      overtime_hours { (check_out - check_in) / 1.hour }
      regular_hours { 0 }
    end
    
    trait :today do
      work_date { Date.current }
    end
    
    trait :yesterday do
      work_date { Date.current - 1.day }
    end
  end
end