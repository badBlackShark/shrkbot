# frozen_string_literal: true

module SetsTwilightStruggleServers
  extend ActiveSupport::Concern

  include SetsManageableServers
  include DiscordReauth

  included do
    before_action :set_twilight_struggle_servers
  end

  private

  def set_twilight_struggle_servers
    @twilight_struggle_servers = TwilightStruggle::AccessibleServers.new(
      user: current_user,
      manageable_discord_ids: live_manageable_ids
    ).all
    return if current_user.owner? || @twilight_struggle_servers.any?

    redirect_to servers_path, alert: t("twilight_struggle.no_access")
  end

  def manages?(tournament)
    current_user.owner? || @twilight_struggle_servers.any? { |server| server.id == tournament.server_configuration_id }
  end
end
