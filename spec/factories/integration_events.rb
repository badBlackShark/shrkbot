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
end
