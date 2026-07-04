# frozen_string_literal: true

class Notifications::ReadsController < ApplicationController
  include SetsManageableServers

  def create
    configs = authorized_server_configurations
    Ops::Notifications::MarkRead.call(server_configurations: configs)
    redirect_to notifications_path(server_id: params[:server_id])
  end

  private

  def authorized_server_configurations
    if params[:server_id]
      ServerConfiguration.where(discord_id: [params[:server_id]].select { |id| manageable_server_ids.include?(id.to_i) })
    else
      ServerConfiguration.where(discord_id: manageable_server_ids)
    end
  end
end
