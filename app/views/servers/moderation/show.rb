# frozen_string_literal: true

class Views::Servers::Moderation::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Components::PluginNav

  def initialize(server_configuration:, user:, context:)
    @config = server_configuration
    @user = user
    @context = context
  end

  def view_template
    render Components::PluginShell.new(
      user: @user,
      server_configuration: @config,
      active_key: :moderation
    ) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(
          icon: "shield",
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url: server_moderation_path(@config.discord_id),
        gate: shell_gate,
        toggle: shell_toggle
      ) do
        logging_subline
        render Components::Moderation::OverviewForm.new(
          server_configuration: @config,
          context: @context
        )
      end
      sub_plugin_toggle_forms
    end
  end

  private

  def sub_plugin_toggle_forms
    PluginCatalog.sub_plugin_keys(:moderation).each do |key|
      form_with(
        url: plugin_config_path(@config.discord_id, key),
        method: :patch,
        id: Components::Moderation::SubPluginRow.toggle_form_id(key),
        class: "hidden"
      ) do
      end
    end
  end

  def shell_gate
    if !@context.logging_ready?
      {
        type: :prereq,
        icon: "scroll",
        title: t(".prereq_gate_title"),
        message: t(".prereq_gate_message"),
        cta_label: t(".prereq_gate_cta"),
        cta_href: server_logging_path(@config.discord_id)
      }
    elsif !@context.group_enabled?
      {
        type: :enable,
        message: t(".gate_message")
      }
    end
  end

  def shell_toggle
    if !@context.logging_ready?
      {
        field: "moderation[enabled]",
        enabled: @context.group_enabled?,
        locked: true,
        reason: t(".toggle_locked_reason")
      }
    else
      {
        field: "moderation[enabled]",
        enabled: @context.group_enabled?,
        locked: false
      }
    end
  end

  def logging_subline
    return unless @context.logging_ready? && @context.logging_channel_name

    p(class: "mb-6 flex items-center gap-1.5 pl-16 text-xs text-text-muted") do
      render Components::Icon.new("scroll", class: "size-4")
      span do
        plain t(".logging_subline_prefix")
        code(class: "font-mono") { "##{@context.logging_channel_name}" }
        plain " "
        plain t(".logging_subline_suffix")
      end
    end
  end
end
