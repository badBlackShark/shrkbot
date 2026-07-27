# frozen_string_literal: true

class Servers::TwilightStruggleController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include AuthorizesTournaments

  before_action :require_toggle_access, only: :update

  def show
    render Views::Servers::TwilightStruggle::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?,
      subscriptions:,
      archived: archived_filter?,
      toggleable: plugin_access.toggle?(::TwilightStruggle::PLUGIN_KEY)
    )
  end

  def update
    result = Ops::TwilightStruggle::Configure.call(
      server_configuration: @server_configuration,
      enabled: twilight_struggle_params[:enabled]
    )
    respond_with_configuration(result)
  end

  private

  def subscriptions
    TwilightStruggle::SubscriptionList.new(
      server_configuration: @server_configuration,
      archived: archived_filter?,
      tournaments: authorized_tournaments
    ).rows
  end

  def archived_filter?
    params[:archived].present?
  end

  def twilight_struggle_params
    params.expect(twilight_struggle: [:enabled])
  end
end
