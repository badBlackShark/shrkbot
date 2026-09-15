# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_game, class: "TwilightStruggle::Game" do
    association :tournament, factory: :twilight_struggle_tournament
    sequence(:external_id) { |n| (1000 + n).to_s }
  end
end
