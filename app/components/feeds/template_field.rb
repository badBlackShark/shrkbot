# frozen_string_literal: true

class Components::Feeds::TemplateField < Components::Base
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

  def source
    ::Feeds.source(@plugin_key)
  end

  def key
    ::Feeds.event_key(@event_type)
  end

  def field_id
    "subscription_#{param}_#{key}"
  end

  def textarea_field
    render Components::TemplateTextarea.new(
      name: "subscription[#{param}][#{@event_type}]",
      id: field_id,
      value:,
      placeholder:,
      data: textarea_data
    )
  end

  def textarea_data
    {feed_preview_target: "template", action: "input->feed-preview#render", tokens: samples.tokens(token_names).to_json}
  end

  def placeholder
    nil
  end

  def samples
    @samples ||= "::Feeds::#{@plugin_key.to_s.camelize}::PreviewSamples".constantize.new(watch_name: @subscription.watch.name, event_type: @event_type)
  end

  def placeholder_help
    render Components::PlaceholderSection.new do
      render Components::PlaceholderChips.new(tokens: placeholders)
    end
  end

  def placeholders
    token_names.index_with { |name| t("components.feeds.placeholders.#{name}") }
  end

  def preview
    render Components::DiscordMessagePreview.new(
      label: preview_label,
      messages: [{body_data: {feed_preview_target: "output"}, card:}]
    )
  end

  def card
    nil
  end
end
