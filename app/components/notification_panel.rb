# frozen_string_literal: true

class Components::NotificationPanel < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(authorized:, server_id: nil)
    @authorized = authorized
    @server_id = server_id
    @groups = authorized.groups
    @presenters = @groups.flat_map { |_config, notifications| notifications.map { |n| NotificationPresenter.new(n) } }
  end

  def view_template
    div(class: "overflow-hidden rounded-lg border border-border-default bg-surface-card shadow-lg") do
      panel_header
      panel_body
    end
  end

  private

  def panel_header
    div(class: "flex flex-col gap-2.5 border-b border-border-subtle px-4 pb-3 pt-3.5") do
      div(class: "flex items-center justify-between") do
        h3(class: "font-display text-sm font-bold tracking-tight") { t(".title") }
        mark_all_read_button if @presenters.any?
      end
      scope_toggle
    end
  end

  def mark_all_read_button
    button_to(
      notifications_read_path(server_id: @server_id),
      method: :post,
      class: "text-xs font-semibold text-text-link hover:underline"
    ) { t(".mark_all_read") }
  end

  def scope_toggle
    div(class: "inline-flex self-start rounded-md bg-surface-sunken p-0.5 text-xs") do
      this_server_active = @server_id.present?

      a(
        href: notifications_path(server_id: current_server_id, open: true),
        data: {turbo_frame: "notifications"},
        class: toggle_tab_class(this_server_active)
      ) { t(".this_server") }

      a(
        href: notifications_path(open: true),
        data: {turbo_frame: "notifications"},
        class: toggle_tab_class(!this_server_active)
      ) { t(".all_servers") }
    end
  end

  def toggle_tab_class(active)
    base = "rounded-[6px] px-2.5 py-1 transition-colors"
    if active
      "#{base} bg-surface-card font-semibold text-text-primary shadow-sm"
    else
      "#{base} font-medium text-text-secondary hover:text-text-primary"
    end
  end

  def panel_body
    div(class: "notif-scroll max-h-[330px] overflow-y-auto") do
      if @presenters.empty?
        empty_state
      elsif @server_id.present?
        flat_items
      else
        grouped_items
      end
      div(class: "h-2") unless @presenters.empty?
    end
  end

  def empty_state
    div(class: "px-6 py-10 text-center") do
      span(class: "mx-auto flex size-10 items-center justify-center rounded-full bg-surface-sunken") do
        render Components::Icon.new("bell", class: "size-5 text-text-muted")
      end
      p(class: "mt-3 text-sm font-semibold") { t(".empty_title") }
      p(class: "mt-1 text-xs text-text-muted") { t(".empty_subtitle") }
    end
  end

  def flat_items
    ul do
      @presenters.each { |presenter| render Components::NotificationItem.new(presenter:, server_id: @server_id) }
    end
  end

  def grouped_items
    @groups.each_with_index do |(config, notifications), index|
      div(class: group_header_class(index)) do
        render Components::ServerAvatar.new(server: config, size: :xs)
        span(class: "text-[11px] font-semibold text-text-secondary truncate") { config.name }
      end
      ul do
        notifications.each do |notification|
          render Components::NotificationItem.new(
            presenter: NotificationPresenter.new(notification),
            server_id: @server_id
          )
        end
      end
    end
  end

  def group_header_class(index)
    base = "flex items-center gap-2 px-4 pb-1.5 pt-3"
    (index > 0) ? "#{base} mt-1 border-t border-border-subtle" : base
  end

  def current_server_id
    @server_id
  end
end
