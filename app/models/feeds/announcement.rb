# frozen_string_literal: true

module Feeds
  class Announcement
    DEFAULT_TEMPLATES = {
      "Integrations::Steam::PatchNotesPublished" => "{role} New {game} patch notes: {title}",
      "Integrations::Steam::AnnouncementPublished" => "{role} New {game} announcement: {title}",
      "Integrations::Steam::ArticlePublished" => "{role} {feed}: {title}"
    }.freeze
    SUBJECT_LIMIT = 2000
    TITLE_LIMIT = 256
    LINK_LABEL = "Read the full post"

    def initialize(event:, subscription:)
      @event = event
      @subscription = subscription
    end

    def subject
      @subject ||= Bot::Discord::Truncate.call(TemplateText.render(template, tokens).strip, SUBJECT_LIMIT)
    end

    def fallback
      "#{Bot::Discord::Truncate.call(subject, SUBJECT_LIMIT - event.url.to_s.length - 1)}\n#{event.url}"
    end

    def card
      Bot::Discord::Components.container(
        blocks,
        buttons: [Bot::Discord::Components.link_button(url: event.url, label: LINK_LABEL)]
      )
    end

    private

    attr_reader :event, :subscription

    def template
      subscription.subscribed_events.where(event_type: event.type).pick(:template).presence || DEFAULT_TEMPLATES.fetch(event.type)
    end

    def tokens
      {
        role: subscription.role_id ? "<@&#{subscription.role_id}>" : "",
        game: event.watch.name,
        title: event.title,
        url: event.url,
        author: event.author,
        feed: event.feed_label
      }
    end

    def blocks
      [heading, excerpt, image].compact
    end

    def heading
      Bot::Discord::Components.text("## #{Bot::Discord::Truncate.call(event.title, TITLE_LIMIT)}")
    end

    def excerpt
      body = Excerpt.new(event.body, subscription.body_length).to_s
      Bot::Discord::Components.text(body) if body.present?
    end

    def image
      url = Array(event.image_urls).first
      Bot::Discord::Components.media_gallery([url]) if url
    end
  end
end
