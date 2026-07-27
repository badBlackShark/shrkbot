# frozen_string_literal: true

FactoryBot.define do
  factory :twilight_struggle_tournament_admin, class: "TwilightStruggle::TournamentAdmin" do
    tournament factory: :twilight_struggle_tournament
    sequence(:discord_id) { |n| 700_000_000_000_000_000 + n }
  end
end
