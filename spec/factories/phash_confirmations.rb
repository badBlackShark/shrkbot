# frozen_string_literal: true

FactoryBot.define do
  factory :phash_confirmation, class: "Moderation::PhashConfirmation" do
    association :phash
    association :server_configuration
    verdict { "confirmed" }
  end
end
