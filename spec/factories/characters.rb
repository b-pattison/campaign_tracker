FactoryBot.define do
  factory :character do
    association :campaign
    name { "Finch" }
    class_name { "Wizard" }
    subclass_name { "Abjuration" }
    level { 5 }
    ancestry { "Elf" }
    notes { "Abjuration specialist raised in a tower. Part of a super secret society of artifact hunters called the Seekers." }
    pc { true }
  end
end