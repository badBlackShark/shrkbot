# frozen_string_literal: true

class Components::ConfigPage < Components::Base
  def initialize(icon:, title:, description:, dashboard_path:)
    @icon = icon
    @title = title
    @description = description
    @dashboard_path = dashboard_path
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
      header
      yield
    end
  end

  private

  def header
    div(class: "mb-6 flex items-start gap-4") do
      render Components::PluginTile.new(icon: @icon, size: :lg)
      div do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @title }
        p(class: "mt-1 text-sm text-text-secondary") { @description }
      end
    end
  end
end
