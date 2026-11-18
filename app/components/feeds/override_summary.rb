# frozen_string_literal: true

class Components::Feeds::OverrideSummary < Components::Base
  SEPARATOR = " · "
  Labels = Data.define(:channels, :roles)

  def initialize(channel_id:, role_id:, labels:)
    @channel_id = channel_id
    @role_id = role_id
    @labels = labels
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
    label = @labels.channels[@channel_id]
    t(".posts_in", channel: label) if label
  end

  def pings
    return t(".pings_no_one") if @role_id == ::Feeds::Twitch::Settings::NO_PING

    name = @labels.roles[@role_id]
    t(".pings", role: name) if name
  end
end
