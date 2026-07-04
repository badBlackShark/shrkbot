# frozen_string_literal: true

class NotificationsController < ApplicationController
  include SetsManageableServers

  def index
    scope = notification_scope
    authorized = AuthorizedNotifications.new(
      manageable_ids: manageable_server_ids,
      server_id: (scope == "server") ? params[:server_id] : nil
    )
    render Views::Notifications::Index.new(
      authorized:,
      server_id: params[:server_id],
      scope:,
      open: params[:open].present?
    )
  end

  def show
    notification = authorized_notification
    return head(:not_found) unless notification

    Ops::Notifications::Read.call(notification:)
    redirect_to plugin_config_path_for(notification)
  end

  def update
    notification = authorized_notification
    return head(:not_found) unless notification

    Ops::Notifications::Dismiss.call(notification:)
    redirect_to notifications_path(server_id: params[:server_id], scope: params[:scope], open: true)
  end

  private

  CONFIGURABLE_PLUGINS = %w[roles welcomes logging reminders].freeze

  def plugin_config_path_for(notification)
    discord_id = notification.server_configuration.discord_id
    key = notification.data["plugin_key"].to_s
    return server_path(discord_id) unless CONFIGURABLE_PLUGINS.include?(key)

    public_send("server_#{key}_path", discord_id)
  end

  def notification_scope
    return params[:scope] if params[:scope].present?

    params[:server_id].present? ? "server" : "all"
  end

  def authorized_notification
    Notification
      .joins(:server_configuration)
      .where(server_configurations: {discord_id: manageable_server_ids})
      .find_by(id: params[:id])
  end
end
