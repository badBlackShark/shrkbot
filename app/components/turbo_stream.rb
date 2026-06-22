# frozen_string_literal: true

# Composes a Turbo Stream response out of Phlex components, so the stream markup
# lives in the view layer rather than in controller helpers. Build it fluently
# and render it:
#   render turbo_stream: render_to_string(
#     Components::TurboStream.new
#       .replace("plugin-roles", Components::PluginRow.new(...))
#       .append("toasts", Components::Toast.new(...)),
#     layout: false
#   )
class Components::TurboStream < Components::Base
  register_element :turbo_stream

  def initialize
    @operations = []
  end

  def replace(target, component)
    @operations << [:replace, target, component]
    self
  end

  def append(target, component)
    @operations << [:append, target, component]
    self
  end

  def view_template
    @operations.each do |action, target, component|
      turbo_stream(action:, target:) do
        template { render component }
      end
    end
  end
end
