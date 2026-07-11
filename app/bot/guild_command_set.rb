# frozen_string_literal: true

class GuildCommandSet
  def initialize(discord_id, commands: BaseCommand.descendants)
    @discord_id = discord_id
    @commands = commands.select(&:registrable)
  end

  def payloads
    included_commands.map { |klass| CommandPayload.new(klass.registration).to_h }
  end

  private

  def included_commands
    @commands.select { |klass| include_command?(klass) }
  end

  def include_command?(klass)
    reg = klass.registration
    return include_global? if reg.global?
    return owner_guild? if reg.context == :owner_guild

    include_guild?(reg)
  end

  def owner_guild?
    owner_guild_id = BotConfig.owner_guild_id
    owner_guild_id.present? && @discord_id.to_s == owner_guild_id.to_s
  end

  def include_global?
    Rails.env.development?
  end

  def include_guild?(reg)
    return true if reg.plugin.nil?

    parent_key = PluginCatalog.find(reg.plugin)&.parent
    enabled_keys.include?(reg.plugin) && (parent_key.nil? || enabled_keys.include?(parent_key))
  end

  def enabled_keys
    @enabled_keys ||= fetch_enabled_keys
  end

  def fetch_enabled_keys
    config = ServerConfiguration.find_by(discord_id: @discord_id)
    return [] unless config

    config.plugins.enabled.pluck(:key).map(&:to_sym)
  end
end
