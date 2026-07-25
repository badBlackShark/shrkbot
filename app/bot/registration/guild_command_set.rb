# frozen_string_literal: true

module Bot
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
      owner_guild_id = Config.owner_guild_id
      owner_guild_id.present? && @discord_id.to_s == owner_guild_id.to_s
    end

    def include_global?
      Rails.env.development?
    end

    def include_guild?(reg)
      return true if reg.plugin.nil?

      definition = PluginCatalog.find(reg.plugin)
      return false unless bespoke_granted?(definition)

      parent_key = definition&.parent
      enabled_keys.include?(reg.plugin) && (parent_key.nil? || enabled_keys.include?(parent_key))
    end

    def bespoke_granted?(definition)
      return true unless definition&.bespoke

      granted_keys.include?(definition.key)
    end

    def granted_keys
      @granted_keys ||= server_configuration ? BespokePluginGrant.granted_keys(server_configuration) : Set.new
    end

    def enabled_keys
      @enabled_keys ||= server_configuration ? server_configuration.plugins.enabled.pluck(:key).map(&:to_sym) : []
    end

    def server_configuration
      @server_configuration ||= ServerConfiguration.find_by(discord_id: @discord_id)
    end
  end
end
