# frozen_string_literal: true

class Components::Feeds::OverrideSummary < Components::Base
  SEPARATOR = " · "

  def initialize(channel_id:, role_id:, channel_labels:, role_names:)
    @channel_id = channel_id
    @role_id = role_id
    @channel_labels = channel_labels
    @role_names = role_names
  end

  def view_template
    return if parts.empty?

    p(class: "mt-0.5 text-sm text-text-secondary") { parts.join(SEPARATOR) }
  end

  private

  def parts
    @parts ||= [posts_in, pings].compact
  end

  def posts_in
    label = @channel_labels[@channel_id]
    t(".posts_in", channel: label) if label
  end

  def pings
    name = @role_names[@role_id]
    t(".pings", role: name) if name
  end
end
