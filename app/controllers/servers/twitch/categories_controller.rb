# frozen_string_literal: true

class Servers::Twitch::CategoriesController < ApplicationController
  include RequiresManageableServer

  rate_limit to: 60, within: 1.minute, by: -> { session[:user_id] }

  def index
    results = ::Feeds::Twitch::CategorySearch.call(params[:query].to_s)
    return render json: [], status: :service_unavailable unless results

    render json: results
  end

  private

  def plugin_key
    :twitch
  end
end
