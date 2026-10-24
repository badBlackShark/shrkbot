# frozen_string_literal: true

class Servers::SteamNewsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::SteamNews::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    result = toggle_plugin(steam_news_params[:enabled])
    return redirect_to_overview(result) if params[:from_overview]

    respond_with_configuration(result)
  end

  private

  def steam_news_params
    params.expect(steam_news: [:enabled])
  end
end
