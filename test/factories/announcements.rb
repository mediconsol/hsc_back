# Factory for Announcement model
FactoryBot.define do
  factory :announcement do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    author { Faker::Name.name }
    category { %w[general urgent maintenance training meeting].sample }
    priority { %w[low normal high urgent].sample }
    is_published { true }
    published_at { Faker::Time.between(from: 1.month.ago, to: Time.current) }
    
    trait :urgent do
      priority { 'urgent' }
      category { 'urgent' }
      title { '[긴급] ' + Faker::Lorem.sentence }
    end
    
    trait :maintenance do
      category { 'maintenance' }
      priority { 'high' }
      title { '[점검 공지] ' + Faker::Lorem.sentence }
    end
    
    trait :meeting do
      category { 'meeting' }
      title { '[회의 안내] ' + Faker::Lorem.sentence }
    end
    
    trait :training do
      category { 'training' }
      title { '[교육 안내] ' + Faker::Lorem.sentence }
    end
    
    trait :draft do
      is_published { false }
      published_at { nil }
    end
    
    trait :published do
      is_published { true }
      published_at { Faker::Time.between(from: 1.week.ago, to: Time.current) }
    end
    
    trait :scheduled do
      is_published { false }
      published_at { Faker::Time.between(from: 1.hour.from_now, to: 1.week.from_now) }
    end
    
    trait :recent do
      published_at { Faker::Time.between(from: 1.day.ago, to: Time.current) }
    end
    
    trait :old do
      published_at { Faker::Time.between(from: 3.months.ago, to: 1.month.ago) }
    end
  end
end