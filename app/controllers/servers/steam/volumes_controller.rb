# frozen_string_literal: true

class Servers::Steam::VolumesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include RateLimitsExternalCalls

  rate_limit_external_calls

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
