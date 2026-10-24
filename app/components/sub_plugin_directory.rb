# frozen_string_literal: true

class Components::SubPluginDirectory < Components::Base
  def initialize(server_configuration:, parent:, toggle_fields: ->(_key) { {} })
    @config = server_configuration
    @parent = parent
    @toggle_fields = toggle_fields
  end

  def view_template
    div do
      p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-text-muted") do
        t(".eyebrow")
      end
      div(class: "flex flex-col gap-3") do
        rows.each do |row|
          render Components::SubPluginRow.new(
            server_configuration: @config,
            row:,
            group_enabled:
          )
        end
      end
    end
  end

  private

  def rows
    SubPluginStatus.rows(@config, parent: @parent, enabled_keys:) { |key| @toggle_fields.call(key) }
  end

  def group_enabled
    enabled_keys.include?(@parent)
  end

  def enabled_keys
    @enabled_keys ||= @config.enabled_plugin_keys
  end
end
