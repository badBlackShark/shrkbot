# frozen_string_literal: true

class Views::Servers::Moderation::SubPluginShow < Views::Base
  def initialize(server_configuration:, user:, context:)
    @config = server_configuration
    @user = user
    @context = context
  end

  def view_template
    render Components::PluginShell.new(
      user: @user,
      server_configuration: @config,
      active_key:
    ) do
      render Components::Moderation::ConfigShell.new(
        header: Components::ConfigPageHeader.new(
          icon:,
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url:,
        gate: shell_gate,
        toggle: shell_toggle,
        breadcrumb_extra: t(".title")
      ) do
        group_subline
        no_role_callout
        render form
      end
    end
  end

  private

  def shell_gate
    return if @context.group_enabled?

    {
      type: :prereq,
      icon: "shield",
      title: t(".prereq_gate_title"),
      message: t(".prereq_gate_message"),
      cta_label: t(".prereq_gate_cta"),
      cta_href: server_moderation_path(@config.discord_id)
    }
  end

  def shell_toggle
    {
      field: enable_field,
      enabled: @context.plugin_enabled?,
      locked: toggle_locked?,
      reason: toggle_reason
    }
  end

  def toggle_locked?
    !@context.group_enabled? || !@context.staff_role_present?
  end

  def toggle_reason
    return t(".group_locked_reason") unless @context.group_enabled?

    t(".role_locked_reason") unless @context.staff_role_present?
  end

  def group_subline
    p(class: "text-xs text-text-muted mb-6 flex items-center gap-1.5 pl-16") do
      render Components::Icon.new("shield", class: "size-4")
      span do
        plain t(".subline_prefix")
        a(href: server_moderation_path(@config.discord_id), class: "underline hover:text-text-secondary") do
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
        a(href: server_moderation_path(@config.discord_id), class: "underline") { t(".no_role_callout_link") }
        plain t(".no_role_callout_suffix")
      end
    end
  end
end
