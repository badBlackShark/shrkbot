# frozen_string_literal: true

class Components::SubPluginDirectory < Components::Base
  def initialize(server_configuration:, parent:, heading: nil)
    @config = server_configuration
    @parent = parent
    @heading = heading
  end

  def view_template
    div do
      heading
      div(class: "flex flex-col gap-3") do
        rows.each do |row|
          render Components::SubPluginRow.new(
            server_configuration: @config,
            row:
          )
        end
      end
    end
  end

  private

  def heading
    return unless @heading

    p(class: "mb-3 text-[11px] font-semibold uppercase tracking-widest text-text-muted") { @heading }
  end

  def rows
    SubPluginStatus.rows(@config, parent: @parent)
  end
end
