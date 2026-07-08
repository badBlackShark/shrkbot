# frozen_string_literal: true

FactoryBot.define do
  factory :phash, class: "Moderation::Phash" do
    sequence(:phash) { |n| n.to_s(16).rjust(16, "0") }
    last_seen_at { Time.current }
  end
end
