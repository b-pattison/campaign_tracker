FactoryBot.define do
  factory :session do
    association :campaign
    scheduled_at { 1.day.from_now }
    recap { "Session recap notes" }
    location { "The Tavern" }
    status { "planned" }
  end
end
