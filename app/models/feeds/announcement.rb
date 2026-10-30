# frozen_string_literal: true

module Feeds
  class Announcement
    SUBJECT_LIMIT = 2000
    TITLE_LIMIT = 256
    TEXT_LIMIT = 4000
    LINK_LABEL = "Read the full post"
    TYPE_LABELS = {
      "Integrations::Steam::PatchNotesPublished" => "Patch notes",
      "Integrations::Steam::AnnouncementPublished" => "Announcement"
    }.freeze

    def self.eyebrow(game, event_type, feed_label)
      "#{game} · #{TYPE_LABELS.fetch(event_type, feed_label)}"
    end

    def initialize(event:, subscription:, thumbnail: nil)
      @event = event
      @subscription = subscription
      @thumbnail = thumbnail
    end

    def subject
      @subject ||= Bot::Discord::Truncate.call([role_mention, custom_text.presence || headline].compact.join(" "), SUBJECT_LIMIT)
    end

    def fallback
      "#{Bot::Discord::Truncate.call(subject, SUBJECT_LIMIT - event.url.to_s.length - 1)}\n#{event.url}"
    end

    def card
      Bot::Discord::Components.container(
        blocks,
        buttons: [Bot::Discord::Components.link_button(url: event.url, label: LINK_LABEL)],
        lead:
      )
    end

    def attachments
      [Bot::Discord::FileUpload.new(thumbnail, Thumbnail::FILENAME)] if thumbnail
    end

    def allowed_mentions
      role_id ? {parse: [], roles: [role_id]} : {parse: []}
    end

    private

    attr_reader :event, :subscription, :thumbnail

    def subscribed_event
      return @subscribed_event if defined?(@subscribed_event)

      @subscribed_event = subscription.subscribed_events.find_by(event_type: event.type)
    end

    def template
      subscribed_event&.template.to_s
    end

    def role_id
      subscribed_event&.role_id
    end

    def role_mention
      "<@&#{role_id}>" if role_id
    end

    def tokens
      {
        game: event.watch.name,
        author: event.author,
        feed: event.feed_label
      }
    end

    def custom_text
      @custom_text ||= Templates.strip(TemplateText.render(template, tokens))
    end

    def eyebrow_plain
      @eyebrow_plain ||= self.class.eyebrow(event.watch.name, event.type, event.feed_label)
    end

    def headline
      "#{eyebrow_plain}: #{event.title}"
    end

    def lead
      @lead ||= begin
        text = [role_mention, custom_text.presence].compact.join(" ").presence
        text && Bot::Discord::Truncate.call(text, SUBJECT_LIMIT)
      end
    end

    def blocks
      [*header, excerpt, image].compact
    end

    def header
      texts = [eyebrow, heading]
      return texts unless thumbnail

      [Bot::Discord::Components.section(texts, accessory: Bot::Discord::Components.thumbnail("attachment://#{Thumbnail::FILENAME}"))]
    end

    def eyebrow_markdown
      "-# #{eyebrow_plain}"
    end

    def eyebrow
      Bot::Discord::Components.text(eyebrow_markdown)
    end

    def heading_text
      @heading_text ||= "## #{Bot::Discord::Truncate.call(event.title, TITLE_LIMIT)}"
    end

    def heading
      Bot::Discord::Components.text(heading_text)
    end

    def excerpt
      budget = TEXT_LIMIT - lead.to_s.length - eyebrow_markdown.length - heading_text.length
      body = Excerpt.new(event.body, subscription.body_length, max: budget).to_s
      Bot::Discord::Components.text(body) if body.present?
    end

    def image
      url = Array(event.image_urls).first
      Bot::Discord::Components.media_gallery([url]) if url
    end
  end
end
