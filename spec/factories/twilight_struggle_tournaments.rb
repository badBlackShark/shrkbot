# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_tournament, class: "TwilightStruggle::Tournament" do
    sequence(:external_id) { |n| "tst-ext-#{n}" }
    name { "Ameritash 2026" }
  end
end
