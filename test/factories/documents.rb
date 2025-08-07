# Factory for Document model
FactoryBot.define do
  factory :document do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 5).join("\n\n") }
    file_path { "/documents/#{Faker::File.file_name(dir: 'files', ext: 'pdf')}" }
    file_size { Faker::Number.between(from: 1024, to: 10_485_760) } # 1KB to 10MB
    mime_type { 'application/pdf' }
    category { %w[policy procedure form manual guideline].sample }
    version { "v#{Faker::Number.between(from: 1, to: 5)}.#{Faker::Number.between(from: 0, to: 9)}" }
    is_active { true }
    created_by { Faker::Name.name }
    
    trait :policy do
      category { 'policy' }
      title { '[정책] ' + Faker::Lorem.sentence }
      mime_type { 'application/pdf' }
    end
    
    trait :procedure do
      category { 'procedure' }
      title { '[절차서] ' + Faker::Lorem.sentence }
    end
    
    trait :form do
      category { 'form' }
      title { '[양식] ' + Faker::Lorem.sentence }
      mime_type { 'application/vnd.ms-excel' }
    end
    
    trait :manual do
      category { 'manual' }
      title { '[매뉴얼] ' + Faker::Lorem.sentence }
    end
    
    trait :guideline do
      category { 'guideline' }
      title { '[가이드라인] ' + Faker::Lorem.sentence }
    end
    
    trait :active do
      is_active { true }
    end
    
    trait :inactive do
      is_active { false }
    end
    
    trait :large_file do
      file_size { Faker::Number.between(from: 10_485_760, to: 52_428_800) } # 10MB to 50MB
    end
    
    trait :small_file do
      file_size { Faker::Number.between(from: 1024, to: 102_400) } # 1KB to 100KB
    end
    
    trait :recent do
      created_at { Faker::Time.between(from: 1.week.ago, to: Time.current) }
    end
    
    trait :old do
      created_at { Faker::Time.between(from: 1.year.ago, to: 1.month.ago) }
    end
  end
end