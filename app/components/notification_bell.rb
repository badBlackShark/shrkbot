# frozen_string_literal: true

class Components::NotificationBell < Components::Base
  def initialize(authorized:, server_id: nil, open: false)
    @authorized = authorized
    @server_id = server_id
    @open = open
  end

  def view_template
    details(
      open: @open,
      class: "relative",
      data: {controller: "dropdown"}
    ) do
      summary(
        aria_label: bell_label,
        data: {action: "click->dropdown#toggle"},
        class: "relative flex size-9 cursor-pointer list-none items-center justify-center rounded-md text-text-secondary transition-colors hover:bg-surface-sunken [&::-webkit-details-marker]:hidden"
      ) do
        render Components::Icon.new("bell", class: "size-5")
        unread_badge if @authorized.unread_count > 0
      end

      div(
        data: {dropdown_target: "menu"},
        class: "dropdown-menu absolute right-0 top-12 z-50 w-[380px] max-w-[calc(100vw-2rem)]"
      ) do
        render Components::NotificationPanel.new(authorized: @authorized, server_id: @server_id)
      end
    end
  end

  private

  def unread_badge
    span(
      class: "absolute right-0.5 top-0.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-accent-fill px-1 text-[10px] font-bold leading-4 text-white",
      style: "box-shadow:0 0 0 2px var(--surface-card)"
    ) { @authorized.unread_count.to_s }
  end

  def bell_label
    count = @authorized.unread_count
    if count > 0
      t(".unread", count: count)
    else
      t(".label")
    end
  end
end
