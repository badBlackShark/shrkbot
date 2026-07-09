# frozen_string_literal: true

class Components::Moderation::ConfigShell < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(header:, server_configuration:, url:, toggle:, gate: nil, breadcrumb_extra: nil)
    @header = header
    @server_configuration = server_configuration
    @url = url
    @gate = gate
    @toggle = toggle
    @breadcrumb_extra = breadcrumb_extra
  end

  def view_template(&block)
    div(class: "mx-auto max-w-3xl px-6 pb-28 pt-8") do
      render Components::Breadcrumb.new(breadcrumb_crumbs)
      form_with(
        url: @url,
        method: :patch,
        data: form_data
      ) do
        page_header
        body(&block)
        render Components::SaveBar.new
      end
    end
  end

  private

  def breadcrumb_crumbs
    base = [
      {label: t("components.config_page.servers"), href: servers_path},
      {label: @server_configuration.name || t("components.config_page.dashboard"), href: server_path(@server_configuration.discord_id)},
      {label: t("views.servers.moderation.show.title"), href: @breadcrumb_extra ? server_moderation_path(@server_configuration.discord_id) : nil}
    ]
    base << {label: @breadcrumb_extra} if @breadcrumb_extra
    base
  end

  def form_data
    controllers = ["save-bar"]
    controllers.unshift("enable-gate") if gate_type == :enable
    {
      controller: controllers.join(" "),
      action: "input->save-bar#check change->save-bar#check turbo:submit-end->save-bar#saved"
    }
  end

  def page_header
    div(class: "mb-6 flex items-start gap-4") do
      render Components::PluginTile.new(icon: @header.icon, size: :lg)
      div(class: "flex-1") do
        div(class: "flex flex-wrap items-center gap-3") do
          h1(class: "font-display text-2xl font-bold tracking-tight") { @header.title }
          render Components::Badge.new(variant: :copper) { @header.badge } if @header.badge
        end
        p(class: "mt-1 text-sm text-text-secondary") { @header.description }
      end
      enable_control
    end
  end

  def enable_control
    div(class: "flex flex-none items-center gap-2.5 pt-1") do
      if @toggle[:locked]
        locked_enable_control
      else
        interactive_enable_control
      end
    end
  end

  def locked_enable_control
    span(class: "text-sm font-medium text-text-secondary") do
      @toggle[:enabled] ? t("components.config_page.enabled") : t("components.config_page.disabled")
    end
    render Components::Tooltip.new(text: @toggle[:reason]) do
      render Components::Toggle.new(
        name: @toggle[:field],
        checked: @toggle[:enabled],
        label: t("components.config_page.enable", plugin: @header.title),
        disabled: true
      )
    end
  end

  def interactive_enable_control
    span(
      class: "text-sm font-medium text-text-secondary",
      data: enable_gate_type? ? {enable_gate_target: "label", on: t("components.config_page.enabled"), off: t("components.config_page.disabled")} : {}
    ) { @toggle[:enabled] ? t("components.config_page.enabled") : t("components.config_page.disabled") }
    render Components::Toggle.new(
      name: @toggle[:field],
      checked: @toggle[:enabled],
      label: t("components.config_page.enable", plugin: @header.title),
      data: enable_gate_type? ? {enable_gate_target: "toggle", action: "change->enable-gate#update"} : {}
    )
  end

  def body(&block)
    case gate_type
    when :prereq
      render Components::PrereqGate.new(
        title: @gate[:title],
        message: @gate[:message],
        cta_label: @gate[:cta_label],
        cta_href: @gate[:cta_href],
        icon: @gate[:icon] || "lock"
      ) { yield }
    when :enable
      render Components::EnableGate.new(
        enabled: @toggle[:enabled],
        title: t("components.config_page.disabled_title", plugin: @header.title),
        message: @gate[:message],
        enable_label: t("components.config_page.enable", plugin: @header.title)
      ) { yield }
    else
      yield
    end
  end

  def gate_type
    @gate&.fetch(:type)
  end

  def enable_gate_type?
    gate_type == :enable
  end
end
