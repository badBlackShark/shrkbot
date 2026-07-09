# frozen_string_literal: true

class Components::SidebarGroup < Components::Base
  STATUS_TONES = {
    enabled: "bg-success",
    disabled: "bg-border-strong",
    needs_setup: "bg-warning"
  }.freeze

  def initialize(label:, icon:, open:, items:, storage_key:, enabled: false)
    @label = label
    @icon = icon
    @open = open
    @items = items
    @storage_key = storage_key
    @enabled = enabled
  end

  def view_template
    details(
      open: @open || nil,
      class: "group/details",
      data: {
        controller: "disclosure",
        disclosure_key_value: @storage_key
      }
    ) do
      summary_row
      sub_items
    end
  end

  private

  def summary_row
    summary(
      class: "flex cursor-pointer list-none items-center gap-2.5 rounded-md px-2.5 py-2 text-text-secondary transition-colors hover:bg-surface-card [&::-webkit-details-marker]:hidden",
      data: {action: "click->disclosure#toggle"}
    ) do
      parent_tile
      span(class: "flex-1 text-[13px] font-medium") { @label }
      chevron
    end
  end

  def parent_tile
    on = @enabled || @items.any? { |item| item[:active] }
    tone = on ? "bg-accent-fill text-white" : "bg-surface-card text-text-muted"
    span(class: "flex size-7 flex-none items-center justify-center rounded-md #{tone}") do
      render Components::Icon.new(@icon, weight: (on ? :fill : :regular), class: "size-4")
    end
  end

  def chevron
    span(class: "text-text-muted") do
      render Components::Icon.new("caret-right", class: "size-3.5 transition-transform group-open/details:rotate-90")
    end
  end

  def sub_items
    div(class: "ml-3 mt-0.5 border-l border-border-subtle pl-2") do
      @items.each { |item| sub_item(item) }
    end
  end

  def sub_item(item)
    active = item[:active]
    tone = active ? "bg-accent-soft font-semibold text-accent-soft-fg" : "text-text-secondary hover:bg-surface-card"
    a(
      href: item[:href],
      aria_current: ("page" if active),
      class: "flex items-center gap-2 rounded-md px-2.5 py-1.5 text-[13px] transition-colors #{tone}"
    ) do
      span(class: "flex-1") { item[:label] }
      sub_item_dot(item[:status]) if item[:status]
    end
  end

  def sub_item_dot(status)
    tone = STATUS_TONES.fetch(status, "bg-border-strong")
    span(class: "size-1.5 flex-none rounded-full #{tone}")
  end
end
