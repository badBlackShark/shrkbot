module Ops
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

      # Toggle the flag rather than create/destroy, so settings survive a
      # disable→enable cycle (#16).
      activation = PluginActivation.find_or_initialize_by(
        server_configuration: @server_configuration, plugin: @plugin
      )
      transaction { activation.update!(enabled: @enabled) }
      ok(activation)
    end

    private

    # Server-side half of #21 — the web Stimulus gate is UX only, so this stays.
    def prerequisites_met?
      case @plugin.key
      when "logging"
        @server_configuration.logging_setting&.channel_id.present?
      else
        # roles/welcomes prerequisite gates land with those plugins (Phase 4).
        true
      end
    end
  end
end
