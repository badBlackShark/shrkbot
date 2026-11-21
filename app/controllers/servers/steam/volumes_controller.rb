# frozen_string_literal: true

class Servers::Steam::VolumesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  rate_limit to: 60, within: 1.minute, by: -> { session[:user_id] }

  WATCHER = ::Integrations::Steam::NewsWatcher

  def show
    render Views::Servers::Steam::Volumes::Show.new(
      volume: ::Feeds::VolumeLookup.call(WATCHER, params.expect(:app)),
      plugin_key:
    )
  end

  private

  def plugin_key
    :steam
  end
end
