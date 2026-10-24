# frozen_string_literal: true

class Components::SubPluginToggleForms < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(server_configuration:, parent:)
    @config = server_configuration
    @parent = parent
  end

  def view_template
    PluginCatalog.visible_sub_plugin_keys(@parent, @config).each do |key|
      form_with(
        url: PluginPaths.for(@config, key),
        method: :patch,
        id: Components::SubPluginRow.toggle_form_id(key),
        class: "hidden"
      ) do
      end
    end
  end
end
