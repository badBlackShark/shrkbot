# frozen_string_literal: true

class Views::Servers::Moderation::Show < Views::Servers::PluginConfigShow
  include Phlex::Rails::Helpers::FormWith

  def initialize(server_configuration:, user:, context:)
    super(server_configuration:, user:)
    @context = context
  end

  private

  def plugin_key
    :moderation
  end

  def icon
    "shield"
  end

  def enabled?
    @context.group_enabled?
  end

  def body
    logging_subline
    render Components::Moderation::OverviewForm.new(
      server_configuration: @config,
      context: @context
    )
  end

  def after_config_page
    sub_plugin_toggle_forms
  end

  def sub_plugin_toggle_forms
    PluginCatalog.sub_plugin_keys(:moderation).each do |key|
      form_with(
        url: PluginPaths.for(@config, key),
        method: :patch,
        id: Components::Moderation::SubPluginRow.toggle_form_id(key),
        class: "hidden"
      ) do
      end
    end
  end

  def gate
    if !@context.logging_ready?
      {
        type: :prereq,
        icon: "scroll",
        title: t(".prereq_gate_title"),
        message: t(".prereq_gate_message"),
        cta_label: t(".prereq_gate_cta"),
        cta_href: PluginPaths.for(@config, :logging)
      }
    elsif !@context.group_enabled?
      {
        type: :enable,
        message: t(".gate_message")
      }
    end
  end

  def toggle
    return super if @context.logging_ready?

    super.merge(locked: true, reason: t(".toggle_locked_reason"))
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
