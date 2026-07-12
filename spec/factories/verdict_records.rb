# frozen_string_literal: true

FactoryBot.define do
  factory :verdict_record, class: "Moderation::VerdictRecord" do
    association :server_configuration
    discord_user_id { 111_222_333_444_555_666 }
    action { "flag_for_review" }
    punishment { "none" }
  end
end
