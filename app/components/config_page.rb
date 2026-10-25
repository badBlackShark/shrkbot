# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(header:, server_configuration:, url:, toggle: nil, gate: nil, channel_lost: false, parent_crumb: nil, header_aside: nil, header_media: nil)
    @header = header
    @server_configuration = server_configuration
    @url = url
    @toggle = toggle
    @gate = gate
    @channel_lost = channel_lost
    @parent_crumb = parent_crumb
    @header_aside = header_aside
    @header_media = header_media
  end

  def view_template(&block)
    render Components::ServerPage.new(server_configuration: @server_configuration, crumbs: trailing_crumbs) do
      form_with(
        url: @url,
        method: :patch,
        data: form_data
      ) do
        page_header
        body(&block)
        render Components::SaveBar.new(preview: @server_configuration.preview?)
      end
    end
  end

  private

  def trailing_crumbs
    [@parent_crumb, {label: @header.title}].compact
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
      div(class: "mt-2 flex-none") { header_visual }
      div(class: "flex-1") do
        div(class: "flex flex-wrap items-center gap-3") do
          h1(class: "font-display text-2xl font-bold tracking-tight") { @header.title }
          render Components::Badge.new(variant: :copper) { @header.badge } if @header.badge
          render @header_aside if @header_aside
        end
        p(class: "mt-1 text-sm text-text-secondary") { @header.description }
      end
      enable_control if @toggle
    end
  end

  def header_visual
    render(@header_media || Components::PluginTile.new(icon: @header.icon, size: :lg))
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
        label: toggle_label,
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
      label: toggle_label,
      data: enable_gate_type? ? {enable_gate_target: "toggle", action: "change->enable-gate#update"} : {}
    )
  end

  def toggle_label
    @toggle[:label] || t(".enable", plugin: @header.title)
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
