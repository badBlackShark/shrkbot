# frozen_string_literal: true

class NotificationPresenter
  ICON_BY_KIND = {
    "channel_deleted" => "warning"
  }.freeze

  DEFAULT_ICON = "bell"

  attr_reader :notification

  def initialize(notification)
    @notification = notification
  end

  def title
    if notification.kind == "channel_deleted" && notification.data["channel_name"].nil?
      I18n.t("notifications.kinds.channel_deleted.title_unknown")
    else
      I18n.t("notifications.kinds.#{notification.kind}.title", **symbolized_data)
    end
  end

  def message
    I18n.t("notifications.kinds.#{notification.kind}.message", **symbolized_data)
  end

  def icon
    ICON_BY_KIND.fetch(notification.kind, DEFAULT_ICON)
  end

  def unread?
    notification.read_at.nil?
  end

  def relative_time
    "#{ActionController::Base.helpers.time_ago_in_words(notification.created_at)} ago"
  end

  def server_configuration
    notification.server_configuration
  end

  private

  def symbolized_data
    notification.data.transform_keys(&:to_sym)
  end
end
