# frozen_string_literal: true

class Components::Feeds::CustomMessageField < Components::Base
  STORE_URL = "https://store.steampowered.com/news/"

  def initialize(subscription:, plugin_key:, event_type:, event:)
    @subscription = subscription
    @plugin_key = plugin_key
    @event_type = event_type
    @event = event
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
    ::Feeds.event_key(@event_type)
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
      value: @event&.template || ::Feeds::Templates.default(@event_type),
      placeholder: ::Feeds::Templates.default(@event_type),
      data: {feed_preview_target: "template", action: "input->feed-preview#render", tokens: sample_tokens.to_json, optional_tokens: optional_tokens.to_json}
    )
  end

  def optional_tokens
    ::Feeds::Templates::OPTIONAL_TOKENS
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
    render Components::PlaceholderSection.new do
      render Components::PlaceholderChips.new(tokens: placeholders)
    end
  end

  def placeholders
    ::Feeds::Templates::TOKENS_BY_SOURCE.fetch(@plugin_key).index_with { |name| t(".placeholders.#{name}") }
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: t(".preview"),
      messages: [{card:}]
    )
  end

  def card
    {
      lead_data: {feed_preview_target: "output", empty_hint: t(".empty")},
      title: sample(:title),
      body: sample(:body),
      button: ::Feeds::Announcement::LINK_LABEL
    }
  end
end
