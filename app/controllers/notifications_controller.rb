# frozen_string_literal: true

class NotificationsController < ApplicationController
  include SetsManageableServers

  def index
    authorized = AuthorizedNotifications.new(
      manageable_ids: manageable_server_ids,
      server_id: params[:server_id]
    )
    render Views::Notifications::Index.new(
      authorized:,
      server_id: params[:server_id]
    )
  end

  def update
    notification = authorized_notification
    return head(:not_found) unless notification

    Ops::Notifications::Dismiss.call(notification:)
    redirect_to notifications_path(server_id: params[:server_id])
  end

  private

  def authorized_notification
    Notification
      .joins(:server_configuration)
      .where(server_configurations: {discord_id: manageable_server_ids})
      .find_by(id: params[:id])
  end
end
