# frozen_string_literal: true

class Views::Servers::SubPluginShow < Views::Servers::PluginConfigShow
  private

  def enabled?
    enabled_keys.include?(plugin_key)
  end

  def group_enabled?
    enabled_keys.include?(parent_key)
  end

  def enabled_keys
    @enabled_keys ||= @config.enabled_plugin_keys
  end

  def gate
    return if group_enabled?

    {
      type: :prereq,
      icon: plugin_icon(parent_key),
      title: t("views.servers.sub_plugin_show.prereq_gate_title", parent: parent_name),
      message: t("views.servers.sub_plugin_show.prereq_gate_message", plugin: plugin_name, parent: parent_name),
      cta_label: t("views.servers.sub_plugin_show.prereq_gate_cta", parent: parent_name),
      cta_href: parent_path
    }
  end

  def toggle
    super.merge(locked: toggle_locked?, reason: toggle_reason)
  end

  def toggle_locked?
    !group_enabled?
  end

  def toggle_reason
    t("views.servers.sub_plugin_show.group_locked_reason", parent: parent_name) unless group_enabled?
  end

  def parent_name
    PluginCatalog.find(parent_key).name
  end

  def plugin_name
    PluginCatalog.find(plugin_key).name
  end

  def subline_note
    nil
  end

  def group_subline
    p(class: "text-xs text-text-muted mb-6 flex items-center gap-1.5 pl-16") do
      render Components::Icon.new(plugin_icon(parent_key), class: "size-4")
      span do
        plain t("views.servers.sub_plugin_show.subline_prefix")
        a(href: parent_path, class: "underline hover:text-text-secondary") { parent_name }
        plain t("views.servers.sub_plugin_show.subline_suffix")
        if subline_note
          plain " "
          plain subline_note
        end
      end
    end
  end
end
