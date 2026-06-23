class Components::ConfigPage < Components::Base
  def initialize(icon:, title:, description:, dashboard_path:)
    @icon = icon
    @title = title
    @description = description
    @dashboard_path = dashboard_path
  end

  def view_template(&block)
    div(class: "mx-auto max-w-3xl px-6 py-8") do
      breadcrumb
      header
      yield
    end
  end

  private

  def breadcrumb
    nav(class: "mb-4 flex items-center gap-1.5 text-xs text-ink-500") do
      a(href: servers_path, class: "transition-colors hover:text-ink-700") { t(".servers") }
      render Components::Icon.new("chevron-right", class: "size-3")
      a(href: @dashboard_path, class: "transition-colors hover:text-ink-700") { t(".dashboard") }
      render Components::Icon.new("chevron-right", class: "size-3")
      span(class: "font-medium text-ink-700") { @title }
    end
  end

  def header
    div(class: "mb-6 flex items-start gap-4") do
      span(class: "flex size-12 flex-none items-center justify-center rounded-xl bg-brand-100 text-accent-soft-fg") do
        render Components::Icon.new(@icon, class: "size-6")
      end
      div do
        h1(class: "font-display text-2xl font-bold tracking-tight") { @title }
        p(class: "mt-1 text-sm text-ink-600") { @description }
      end
    end
  end
end
