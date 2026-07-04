# frozen_string_literal: true

class CachedDashboard
  def self.for(discord_id:, manageable_ids:)
    configs = ServerConfiguration.where(discord_id: manageable_ids).where.not(name: nil)
    config = configs.find { |candidate| candidate.discord_id == discord_id }
    new(config, configs) if config
  end

  attr_reader :server_configuration

  def initialize(server_configuration, configs)
    @server_configuration = server_configuration
    @configs = configs
  end

  def guild
    configured_guilds.find { |guild| guild.id == server_configuration.discord_id }
  end

  def configured_guilds
    @configured_guilds ||= @configs.sort_by { |config| -config.member_count.to_i }.map { |config| CachedGuild.from(config) }
  end

  def plugin_counts
    PluginActivation.enabled_counts_for(@configs.map(&:discord_id))
  end
end
