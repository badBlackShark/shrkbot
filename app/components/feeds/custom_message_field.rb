# frozen_string_literal: true

class Components::Feeds::CustomMessageField < Components::Base
  STORE_URL = "https://store.steampowered.com/news/"

  def initialize(subscription:, plugin_key:, event_type:)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
  end

  def view_template
    div(class: "flex flex-col gap-3", data: {feed_preview_field: true}) do
      label_row
      textarea_field
      placeholder_help
      preview
    end
  end

  private

  def key
    @event_type.demodulize.underscore
  end

  def field_name
    "subscription[templates][#{@event_type}]"
  end

  def label_row
    div(class: "flex items-center justify-between gap-3") do
      label(for: field_id, class: "text-sm font-semibold") { t(".label") }
      render Components::ResetButton.new(label: t(".reset"), data: {action: "feed-preview#reset"})
    end
  end

  def field_id
    "subscription_templates_#{key}"
  end

  def textarea_field
    render Components::TemplateTextarea.new(
      name: field_name,
      id: field_id,
      value: stored_template,
      placeholder: ::Feeds::Templates.default(@event_type),
      data: {feed_preview_target: "template", action: "input->feed-preview#render", tokens: sample_tokens.to_json}
    )
  end

  def stored_template
    @subscription.subscribed_events.reject(&:marked_for_destruction?).find { |event| event.event_type == @event_type }&.template
  end

  def sample_tokens
    {
      game: @subscription.watch.name,
      title: sample(:title),
      url: STORE_URL,
      author: sample(:author),
      feed: sample(:feed)
    }
  end

  def sample(field)
    t(".samples.#{key}.#{field}")
  end

  def placeholder_help
    render Components::Callout.new(variant: :neutral) do
      render Components::CopyableTokens.new do
        span(class: "font-semibold") { t(".placeholders.intro") }
        ::Feeds::Templates::TOKENS_BY_SOURCE.fetch(@plugin_key).each do |name|
          whitespace
          render Components::TokenChip.new(token: name, description: t(".placeholders.#{name}"))
        end
      end
    end
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: t(".preview"),
      messages: [{body_data: {feed_preview_target: "output", empty_hint: t(".empty")}, card:}]
    )
  end

  def card
    {title: sample(:title), body: sample(:body), button: ::Feeds::Announcement::LINK_LABEL}
  end
end
