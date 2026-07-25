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

  def flash_for(result, success_key)
    return {notice: t("twilight_struggle.#{success_key}")} if result.success?

    {alert: result.errors.to_sentence}
  end

  def manages?(tournament)
    current_user.owner? || hosts?(tournament.server_configuration)
  end

  def hosts?(server_configuration)
    return false if server_configuration.nil?

    @twilight_struggle_servers.any? { |candidate| candidate.id == server_configuration.id }
  end
end
