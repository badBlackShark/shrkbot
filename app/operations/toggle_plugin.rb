# Enable/disable a plugin for a server via the activation's `enabled` flag
# (settings persist through disable→enable cycles, #16). Enabling refuses when
# the plugin's required settings aren't configured yet (#21 — server-side half
# of the invariant; the web Stimulus gate is the UX half).
class TogglePlugin < ApplicationOperation
  def initialize(server_configuration:, plugin:, enabled:)
    @server_configuration = server_configuration
    @plugin = plugin
    @enabled = enabled
  end

  def call
    if @enabled && !prerequisites_met?
      return failure("#{@plugin.name} can't be enabled until its required settings are configured.")
    end

    activation = PluginActivation.find_or_initialize_by(
      server_configuration: @server_configuration, plugin: @plugin
    )
    transaction { activation.update!(enabled: @enabled) }
    ok(activation)
  end

  private

  def prerequisites_met?
    case @plugin.key
    when "logging"
      @server_configuration.logging_setting&.channel_id.present?
    else
      # ponytail: roles/welcomes prerequisite gates land with those plugins (Phase 4).
      true
    end
  end
end
