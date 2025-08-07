# Factory for User model
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { 1 } # staff by default
    
    trait :admin do
      role { 3 }
      name { "Admin User" }
      email { "admin@hospital.com" }
    end
    
    trait :manager do
      role { 2 }
      name { "Manager User" }
      email { "manager@hospital.com" }
    end
    
    trait :staff do
      role { 1 }
      name { "Staff User" }
      email { "staff@hospital.com" }
    end
    
    trait :read_only do
      role { 0 }
      name { "Read Only User" }
      email { "readonly@hospital.com" }
    end
  end
end