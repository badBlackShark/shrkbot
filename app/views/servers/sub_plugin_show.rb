# frozen_string_literal: true

class Views::Servers::SubPluginShow < Views::Servers::PluginConfigShow
  include Components::PluginNav

  private

  def parent_path
    PluginPaths.for(@config, parent_key)
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
      title: t(".prereq_gate_title"),
      message: t(".prereq_gate_message"),
      cta_label: t(".prereq_gate_cta"),
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
    t(".group_locked_reason") unless group_enabled?
  end

  def group_subline
    p(class: "text-xs text-text-muted mb-6 flex items-center gap-1.5 pl-16") do
      render Components::Icon.new(plugin_icon(parent_key), class: "size-4")
      span do
        plain t(".subline_prefix")
        a(href: parent_path, class: "underline hover:text-text-secondary") do
          plain t(".subline_link")
        end
        plain t(".subline_suffix")
      end
    end
  end
end
