# frozen_string_literal: true

class Servers::SteamNews::VolumesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  WATCHER = Integrations::Steam::NewsWatcher

  def show
    render Views::Servers::SteamNews::Volumes::Show.new(
      volume: ::Feeds::VolumeLookup.call(WATCHER, params.expect(:app)),
      plugin_key:
    )
  end

  private

  def plugin_key
    :steam_news
  end
end
