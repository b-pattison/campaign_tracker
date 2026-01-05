FactoryBot.define do
  factory :attendance do
    session_id { nil }
    character_id { nil }
    present { false }
    xp_earned { 1 }
  end
end
