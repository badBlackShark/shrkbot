# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(icon:, title:, description:, server_configuration:, url:, gate: nil, badge: nil)
    @icon = icon
    @title = title
    @description = description
    @server_configuration = server_configuration
    @url = url
    @gate = gate
    @badge = badge
  end

  def view_template(&block)
    div(class: "mx-auto max-w-3xl px-6 pb-28 pt-8") do
      render Components::Breadcrumb.new(
        [
          {label: t(".servers"), href: servers_path},
          {label: @server_configuration.name || t(".dashboard"), href: server_path(@server_configuration.discord_id)},
          {label: @title}
        ]
      )
      form_with(
        url: @url,
        method: :patch,
        data: {
          controller: gated? ? "enable-gate save-bar" : "save-bar",
          action: "input->save-bar#check change->save-bar#check turbo:submit-end->save-bar#saved"
        }
      ) do
        header
        body(&block)
        render Components::SaveBar.new
      end
    end
  end

  private

  def gated?
    !@gate.nil?
  end

  def body(&block)
    return yield unless gated?

    render Components::EnableGate.new(
      enabled: @gate[:enabled],
      title: t(".disabled_title", plugin: @title),
      message: @gate[:message],
      enable_label: t(".enable", plugin: @title)
    ) { yield }
  end

  def header
    div(class: "mb-6 flex items-start gap-4") do
      render Components::PluginTile.new(icon: @icon, size: :lg)
      div(class: "flex-1") do
        div(class: "flex flex-wrap items-center gap-3") do
          h1(class: "font-display text-2xl font-bold tracking-tight") { @title }
          render Components::Badge.new(variant: :copper) { @badge } if @badge
        end
        p(class: "mt-1 text-sm text-text-secondary") { @description }
      end
      enable_control if gated?
    end
  end

  def enable_control
    div(class: "flex flex-none items-center gap-2.5 pt-1") do
      span(
        class: "text-sm font-medium text-text-secondary",
        data: {enable_gate_target: "label", on: t(".enabled"), off: t(".disabled")}
      ) { @gate[:enabled] ? t(".enabled") : t(".disabled") }
      render Components::Toggle.new(
        name: @gate[:field],
        checked: @gate[:enabled],
        label: t(".enable", plugin: @title),
        data: {enable_gate_target: "toggle", action: "change->enable-gate#update"}
      )
    end
  end
end
