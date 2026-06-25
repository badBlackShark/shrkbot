# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(icon:, title:, description:, dashboard_path:, gate:)
    @icon = icon
    @title = title
    @description = description
    @dashboard_path = dashboard_path
    @gate = gate
  end

  def view_template(&block)
    div(class: "mx-auto max-w-3xl px-6 py-8") do
      render Components::Breadcrumb.new(
        [
          {label: t(".servers"), href: servers_path},
          {label: t(".dashboard"), href: @dashboard_path},
          {label: @title}
        ]
      )
      form_with(
        url: @gate[:url],
        method: :patch,
        data: {
          controller: "enable-gate save-bar",
          action: "input->save-bar#check change->save-bar#check turbo:submit-end->save-bar#saved"
        }
      ) do
        header
        render Components::EnableGate.new(
          enabled: @gate[:enabled],
          title: t(".disabled_title", plugin: @title),
          message: @gate[:message],
          enable_label: t(".enable", plugin: @title)
        ) { yield }
        render Components::SaveBar.new
      end
    end
  end

  private

  def header
    div(class: "mb-6 flex items-start gap-4") do
      render Components::PluginTile.new(icon: @icon, size: :lg)
      div(class: "flex-1") do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @title }
        p(class: "mt-1 text-sm text-text-secondary") { @description }
      end
      enable_control
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
