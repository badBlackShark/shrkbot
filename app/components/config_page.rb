# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(header:, server_configuration:, url:, toggle: nil, gate: nil, channel_lost: false, parent_crumb: nil)
    @header = header
    @server_configuration = server_configuration
    @url = url
    @toggle = toggle
    @gate = gate
    @channel_lost = channel_lost
    @parent_crumb = parent_crumb
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
    crumbs = [
      {label: t(".servers"), href: servers_path},
      {label: @server_configuration.name || t(".dashboard"), href: server_path(@server_configuration.discord_id)}
    ]
    crumbs << {label: @parent_crumb[:label], href: @parent_crumb[:href]} if @parent_crumb
    crumbs << {label: @header.title}
    crumbs
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
      enable_control if @toggle
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
      @toggle[:enabled] ? t(".enabled") : t(".disabled")
    end
    render Components::Tooltip.new(text: @toggle[:reason]) do
      render Components::Toggle.new(
        name: @toggle[:field],
        checked: @toggle[:enabled],
        label: t(".enable", plugin: @header.title),
        disabled: true
      )
    end
  end

  def interactive_enable_control
    span(
      class: "text-sm font-medium text-text-secondary",
      data: enable_gate_type? ? {enable_gate_target: "label", on: t(".enabled"), off: t(".disabled")} : {}
    ) { @toggle[:enabled] ? t(".enabled") : t(".disabled") }
    render Components::Toggle.new(
      name: @toggle[:field],
      checked: @toggle[:enabled],
      label: t(".enable", plugin: @header.title),
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
      ) do
        channel_lost_banner
        yield
      end
    when :enable
      render Components::EnableGate.new(
        enabled: @toggle[:enabled],
        title: t(".disabled_title", plugin: @header.title),
        message: @gate[:message],
        enable_label: t(".enable", plugin: @header.title)
      ) do
        channel_lost_banner
        yield
      end
    else
      channel_lost_banner
      yield
    end
  end

  def channel_lost_banner
    return unless @channel_lost

    div(class: "mb-5") do
      render Components::Callout.new(variant: :warning) { t(".channel_lost", plugin: @header.title) }
    end
  end

  def gate_type
    @gate&.fetch(:type)
  end

  def enable_gate_type?
    gate_type == :enable
  end
end
