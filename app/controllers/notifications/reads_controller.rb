# frozen_string_literal: true

class Notifications::ReadsController < ApplicationController
  include SetsManageableServers

  def create
    configs = authorized_server_configurations
    Ops::Notifications::MarkRead.call(server_configurations: configs)
    redirect_to notifications_path(server_id: params[:server_id], scope: params[:scope], open: true)
  end

  private

  def authorized_server_configurations
    if scoped_to_server?
      ServerConfiguration.where(discord_id: params[:server_id])
    else
      ServerConfiguration.where(discord_id: manageable_server_ids)
    end
  end

  def scoped_to_server?
    params[:scope] == "server" &&
      params[:server_id].present? &&
      manageable_server_ids.include?(params[:server_id].to_i)
  end
end
