# frozen_string_literal: true

class Components::NotificationItem < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(presenter:, server_id: nil, scope: "all")
    @presenter = presenter
    @server_id = server_id
    @scope = scope
  end

  def view_template
    li(class: "relative") do
      item_link
      dismiss_button
    end
  end

  private

  def item_link
    a(
      href: notification_path(@presenter.notification.id),
      data: {turbo_frame: "_top"},
      class: "flex gap-3 py-3 pl-5 pr-9 transition-colors hover:bg-surface-sunken"
    ) do
      unread_dot if @presenter.unread?
      icon_circle
      item_content
    end
  end

  def unread_dot
    span(
      class: "absolute left-[7px] top-[27px] size-1.5 rounded-full bg-accent",
      aria_label: "Unread"
    )
  end

  def icon_circle
    circle_class = @presenter.unread? ? "bg-warning-soft" : "bg-warning-soft opacity-60"
    span(class: "flex size-8 flex-none items-center justify-center rounded-full #{circle_class}") do
      render Components::Icon.new(@presenter.icon, class: "size-4 text-warning")
    end
  end

  def item_content
    span(class: "min-w-0 flex-1") do
      title_line
      message_line
      time_line
    end
  end

  def title_line
    weight = @presenter.unread? ? "font-semibold text-text-primary" : "font-medium text-text-secondary"
    span(class: "block text-[13px] leading-snug #{weight}") do
      render Components::Icon.new("hash", class: "inline size-3 text-text-muted")
      plain @presenter.title
    end
  end

  def message_line
    msg_class = @presenter.unread? ? "text-text-secondary" : "text-text-muted"
    span(class: "mt-0.5 block text-xs leading-snug #{msg_class}") { @presenter.message }
  end

  def time_line
    span(class: "mt-1 block text-[11px] text-text-muted") { @presenter.relative_time }
  end

  def dismiss_button
    button_to(
      notification_path(@presenter.notification.id, server_id: @server_id, scope: @scope),
      method: :patch,
      aria_label: "Dismiss",
      class: "absolute right-2 top-1/2 flex size-6 -translate-y-1/2 cursor-pointer items-center justify-center rounded-md text-text-muted transition-colors hover:bg-surface-raised hover:text-text-primary"
    ) do
      render Components::Icon.new("x", class: "size-3.5")
    end
  end
end
