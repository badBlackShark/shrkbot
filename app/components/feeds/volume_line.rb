# frozen_string_literal: true

class Components::Feeds::VolumeLine < Components::Base
  FRAME_ID = "feed-volume"
  ICON = "chart-bar"

  def initialize(volume:, plugin_key:)
    @volume = volume
    @plugin_key = plugin_key
  end

  def render?
    @volume&.sample_size&.positive?
  end

  def view_template
    render Components::Callout.new(variant: :info, icon: ICON) { t(".line", total: @volume.sample_size, counts:) }
  end

  private

  def counts
    ::Feeds::EVENT_TYPES_BY_SOURCE.fetch(@plugin_key).filter_map { |event_type| count_phrase(event_type) }.to_sentence
  end

  def count_phrase(event_type)
    count = @volume.counts.fetch(event_type, 0)
    t(".counts.#{::Feeds.event_key(event_type)}", count:) if count.positive?
  end
end
