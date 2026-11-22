# frozen_string_literal: true

class Servers::Twitch::Categories::StreamsController < ApplicationController
  include RequiresManageableServer
  include RateLimitsExternalCalls

  rate_limit_external_calls

  def index
    return head :not_found unless params[:category_id].to_s.match?(Integrations::Twitch::CategoryWatcher::ID)

    streams = ::Feeds::TwitchCategory::StreamSample.call(params[:category_id])
    return render json: [], status: :service_unavailable unless streams

    render json: streams
  end

  private

  def plugin_key
    :twitch
  end
end
