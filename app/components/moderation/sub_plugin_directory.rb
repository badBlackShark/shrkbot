# frozen_string_literal: true

class Components::Moderation::SubPluginDirectory < Components::Base
  def initialize(server_configuration:, context:)
    @config = server_configuration
    @context = context
  end

  def view_template
    div do
      p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-text-muted") do
        t(".eyebrow")
      end
      div(class: "flex flex-col gap-3") do
        @context.sub_plugin_rows.each do |row|
          render Components::Moderation::SubPluginRow.new(
            server_id: @config.discord_id,
            key: row.key,
            name: row.name,
            description: row.description,
            enabled: row.enabled,
            configured: row.configured,
            settings: row.settings,
            group_enabled: @context.group_enabled?
          )
        end
      end
    end
  end
end
