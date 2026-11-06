# frozen_string_literal: true

FactoryBot.define do
  factory :steam_news_event, class: "Integrations::Steam::PatchNotesPublished" do
    association :watch, factory: :integration_watch
    sequence(:subject_key) { |n| (1000 + n).to_s }
    occurred_at { Time.current }
    title { "Team Fortress 2 Update Released" }
    url { "https://store.steampowered.com/news/286827/" }
    author { "Valve" }
    feed_name { "steam_community_announcements" }
    feed_label { "Community Announcements" }
    body { "An update has been released." }
    image_urls { [] }
    story_key { subject_key }

    factory :steam_announcement_event, class: "Integrations::Steam::AnnouncementPublished"
    factory :steam_article_event, class: "Integrations::Steam::ArticlePublished"
  end

  factory :twitch_stream_started_event, class: "Integrations::Twitch::StreamStarted" do
    association :watch, factory: [:integration_watch, :twitch]
    sequence(:session) { |n| (40_000_000_000 + n).to_s }
    subject_key { "stream:#{session}" }
    occurred_at { Time.current }
    login { "shrkbot_dev" }
    display_name { "shrkbot_dev" }
    title { "Hades II blind run, day 3" }
    category_id { "1145360737" }
    category_name { "Hades II" }
    started_at { Time.current.iso8601 }
    story_key { "stream:#{session}" }
    viewer_count { nil }

    factory :twitch_stream_sampled_event, class: "Integrations::Twitch::StreamSampled" do
      subject_key { "stream-sample:#{session}:#{occurred_at.to_i}" }
      viewer_count { 1204 }
    end

    factory :twitch_stream_updated_event, class: "Integrations::Twitch::StreamUpdated" do
      subject_key { "stream-update:#{session}:#{occurred_at.to_i}" }
    end

    factory :twitch_stream_ended_event, class: "Integrations::Twitch::StreamEnded" do
      subject_key { "stream-end:#{session}" }
      ended_at { occurred_at.iso8601 }
      duration { 11_520 }
      peak_viewers { 1204 }
      stream_ids { [session] }
    end
  end
end
