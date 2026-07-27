# frozen_string_literal: true

class Servers::TwilightStruggle::SubscriptionsController < Servers::TwilightStruggle::BaseController
  def create
    Ops::TwilightStruggle::Destinations::Subscribe.call(destination: @destination)
    redirect_to edit_server_twilight_struggle_destination_path(params[:server_id], @destination.tournament),
      notice: t("servers.twilight_struggle.subscribed")
  end

  def destroy
    Ops::TwilightStruggle::Destinations::Unsubscribe.call(destination: @destination)
    redirect_to server_twilight_struggle_path(params[:server_id]), notice: t("servers.twilight_struggle.unsubscribed")
  end
end
