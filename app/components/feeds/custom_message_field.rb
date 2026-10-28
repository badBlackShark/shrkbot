# frozen_string_literal: true

class Components::Feeds::CustomMessageField < Components::Base
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
    label(for: field_id, class: "text-sm font-semibold") { t(".label") }
  end

  def field_id
    "subscription_templates_#{key}"
  end

  def textarea_field
    render Components::TemplateTextarea.new(
      name: field_name,
      id: field_id,
      value: @event&.template,
      placeholder: t(".placeholder"),
      data: {feed_preview_target: "template", action: "input->feed-preview#render", tokens: sample_tokens.to_json}
    )
  end

  def sample_tokens
    {
      game: @subscription.watch.name,
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
      messages: [{body_data: {feed_preview_target: "output"}, card:}]
    )
  end

  def card
    {
      eyebrow: ::Feeds::Announcement.eyebrow(@subscription.watch.name, @event_type, sample(:feed)),
      title: sample(:title),
      body: sample(:body),
      button: ::Feeds::Announcement::LINK_LABEL
    }
  end
end
