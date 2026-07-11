# frozen_string_literal: true

class ServerDashboard
  Result = Data.define(:server, :server_configuration, :configured_servers, :plugin_counts, :configured_ids)

  def self.resolve(discord_token:, target_id:, cached_ids:)
    new(discord_token:, target_id:, cached_ids:).resolve
  end

  def initialize(discord_token:, target_id:, cached_ids:)
    @discord_token = discord_token
    @target_id = target_id
    @cached_ids = cached_ids
  end

  def resolve
    live
  rescue Bot::Discord::UserGuilds::Unauthorized
    raise
  rescue Bot::Discord::UserGuilds::Error
    cached || raise
  end

  private

  def live
    manageable = ManageableServers.for(@discord_token)
    server = manageable.find { |candidate| candidate.id == @target_id }
    config = ServerConfiguration.find_by(discord_id: @target_id) if server
    return unless server && config

    ids = ServerConfiguration.configured_ids_among(manageable.map(&:id))
    Result.new(
      server:,
      server_configuration: config,
      configured_servers: manageable.select { |candidate| ids.include?(candidate.id) },
      plugin_counts: PluginActivation.enabled_counts_for(ids),
      configured_ids: ids
    )
  end

  def cached
    dashboard = CachedDashboard.for(discord_id: @target_id, manageable_ids: @cached_ids)
    return unless dashboard

    Result.new(
      server: dashboard.server,
      server_configuration: dashboard.server_configuration,
      configured_servers: dashboard.configured_servers,
      plugin_counts: dashboard.plugin_counts,
      configured_ids: @cached_ids
    )
  end
end
