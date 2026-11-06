# frozen_string_literal: true

module Feeds
  class Announcement
    SUBJECT_LIMIT = 2000
    TITLE_LIMIT = 256

    def initialize(event:, subscription:)
      @event = event
      @subscription = subscription
    end

    def subject
      @subject ||= Bot::Discord::Truncate.call([role_mention, custom_text.presence || headline].compact.join(" "), SUBJECT_LIMIT)
    end

    def fallback
      "#{Bot::Discord::Truncate.call(subject, SUBJECT_LIMIT - url.to_s.length - 1)}\n#{url}"
    end

    def card
      Bot::Discord::Components.container(
        blocks,
        accent_color:,
        buttons: [Bot::Discord::Components.link_button(url:, label: link_label)],
        lead:
      )
    end

    def attachments
      nil
    end

    def allowed_mentions
      role_id ? {parse: [], roles: [role_id]} : {parse: []}
    end

    private

    attr_reader :event, :subscription

    def accent_color
      Bot::Config::ACCENT_COLOR
    end

    def post_type
      event.type
    end

    def template
      subscription.subscribed_events.where(event_type: post_type).pick(:template).to_s
    end

    def role_id
      subscription.source.role_id_for(subscription, post_type)
    end

    def role_mention
      "<@&#{role_id}>" if role_id
    end

    def custom_text
      @custom_text ||= Templates.strip(TemplateText.render(template, tokens))
    end

    def lead
      @lead ||= begin
        text = [role_mention, custom_text.presence].compact.join(" ").presence
        text && Bot::Discord::Truncate.call(text, SUBJECT_LIMIT)
      end
    end

    def heading_text
      @heading_text ||= "## #{Bot::Discord::Truncate.call(event.title, TITLE_LIMIT)}"
    end

    def heading
      Bot::Discord::Components.text(heading_text)
    end
  end
end
