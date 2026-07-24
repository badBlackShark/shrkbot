# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_tournament, class: "TwilightStruggle::Tournament" do
    sequence(:external_id) { |n| "tst-ext-#{n}" }
    name { "Ameritash 2026" }

    trait :friendly do
      friendly { true }
      external_id { nil }
      name { "Friendly games" }
    end
  end
end
