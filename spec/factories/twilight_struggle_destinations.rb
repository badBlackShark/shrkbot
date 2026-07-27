# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_destination, class: "TwilightStruggle::Destination" do
    association :tournament, factory: :twilight_struggle_tournament
    association :server_configuration
  end
end
