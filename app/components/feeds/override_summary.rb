# frozen_string_literal: true

class Components::Feeds::OverrideSummary < Components::Base
  SEPARATOR = " · "

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
    t(".posts_in", channel: @labels.channel_text(@channel_id)) if @channel_id
  end

  def pings
    return unless @role_id
    return t(".pings_no_one") if @role_id == ::Feeds::Twitch::Settings::NO_PING

    t(".pings", role: @labels.role_text(@role_id))
  end
end
