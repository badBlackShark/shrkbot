# frozen_string_literal: true

Rails.application.config.to_prepare do
  Integrations::Watch.demanded_by(Feeds::Subscription)
  Integrations::Bus.subscribe(
    Feeds::AnnounceJob,
    to: [
      Integrations::Steam::PatchNotesPublished,
      Integrations::Steam::AnnouncementPublished,
      Integrations::Steam::ArticlePublished
    ]
  )
end
