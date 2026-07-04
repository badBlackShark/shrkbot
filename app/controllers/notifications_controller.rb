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

  def update
    notification = authorized_notification
    return head(:not_found) unless notification

    Ops::Notifications::Dismiss.call(notification:)
    redirect_to notifications_path(server_id: params[:server_id], scope: params[:scope], open: true)
  end

  private

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
