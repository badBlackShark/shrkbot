# frozen_string_literal: true

class Views::Servers::Moderation::SubPluginShow < Views::Servers::PluginConfigShow
  def initialize(server_configuration:, user:, context:)
    super(server_configuration:, user:)
    @context = context
  end

  private

  def enabled?
    @context.plugin_enabled?
  end

  def parent_crumb
    {label: PluginCatalog.find(:moderation).name, href: moderation_path}
  end

  def moderation_path
    PluginPaths.for(@config, :moderation)
  end

  def gate
    return if @context.group_enabled?

    {
      type: :prereq,
      icon: "shield",
      title: t(".prereq_gate_title"),
      message: t(".prereq_gate_message"),
      cta_label: t(".prereq_gate_cta"),
      cta_href: moderation_path
    }
  end

  def toggle
    super.merge(locked: toggle_locked?, reason: toggle_reason)
  end

  def toggle_locked?
    !@context.group_enabled? || !@context.staff_role_present?
  end

  def toggle_reason
    return t(".group_locked_reason") unless @context.group_enabled?

    t(".role_locked_reason") unless @context.staff_role_present?
  end

  def body
    group_subline
    no_role_callout
    render form
  end

  def group_subline
    p(class: "text-xs text-text-muted mb-6 flex items-center gap-1.5 pl-16") do
      render Components::Icon.new("shield", class: "size-4")
      span do
        plain t(".subline_prefix")
        a(href: moderation_path, class: "underline hover:text-text-secondary") do
          plain t(".subline_link")
        end
        plain t(".subline_suffix")
      end
    end
  end

  def no_role_callout
    return unless @context.group_enabled? && !@context.staff_role_present?

    render Components::Callout.new(variant: :warning) do
      span do
        b(class: "text-warning") { t(".no_role_callout_lead") }
        plain " "
        plain t(".no_role_callout_body")
        plain " "
        a(href: moderation_path, class: "underline") { t(".no_role_callout_link") }
        plain t(".no_role_callout_suffix")
      end
    end
  end
end
