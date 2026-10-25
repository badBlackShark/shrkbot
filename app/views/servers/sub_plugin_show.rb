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
end
