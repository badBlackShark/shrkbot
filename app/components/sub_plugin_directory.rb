# frozen_string_literal: true

class Components::SubPluginDirectory < Components::Base
  def initialize(server_configuration:, rows:, group_enabled:)
    @config = server_configuration
    @rows = rows
    @group_enabled = group_enabled
  end

  def view_template
    div do
      p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-text-muted") do
        t(".eyebrow")
      end
      div(class: "flex flex-col gap-3") do
        @rows.each do |row|
          render Components::SubPluginRow.new(
            server_configuration: @config,
            row:,
            group_enabled: @group_enabled
          )
        end
      end
    end
  end
end
