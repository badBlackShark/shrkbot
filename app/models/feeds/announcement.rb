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
      @subject ||= Bot::Discord::Truncate.call([role_mention, notification].compact.join(" "), SUBJECT_LIMIT)
    end

    def fallback
      "#{Bot::Discord::Truncate.call(subject, SUBJECT_LIMIT - url.to_s.length - 1)}\n#{url}"
    end

    def card
      Bot::Discord::Components.container(
        blocks,
        accent_color:,
        buttons:,
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

    def buttons
      [Bot::Discord::Components.link_button(url:, label: link_label)]
    end

    def post_type
      subscription.source.post_type(event.type)
    end

    def stored_templates
      @stored_templates ||= subscription.subscribed_events.where(event_type: post_type).pick(:template, :notification_template)
    end

    def template
      stored_templates&.first.to_s
    end

    def stored_notification
      stored_templates&.last
    end

    def notification
      rendered_notification(stored_notification.presence) || rendered_notification(default_notification)
    end

    def default_notification
      subscription.source.default_notification(post_type)
    end

    def rendered_notification(text)
      Templates.strip(TemplateText.render(text, notification_values)).presence if text
    end

    def notification_values
      blank(subscription.source.notification_tokens).merge(tokens, title: event.title)
    end

    def role_id
      subscription.source.role_id_for(subscription, post_type)
    end

    def role_mention
      "<@&#{role_id}>" if role_id
    end

    def custom_text
      @custom_text ||= Templates.strip(TemplateText.render(template, blank(subscription.source.template_tokens).merge(tokens)))
    end

    def blank(names)
      names.to_h { |name| [name.to_sym, ""] }
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
