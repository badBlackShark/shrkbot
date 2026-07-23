# frozen_string_literal: true

class Components::Lfg::SetupGuideCard < Components::Base
  def view_template
    render Components::Card.new(padding: :none, class: "overflow-hidden") do
      details(data: {controller: "dropdown", dropdown_dismiss_on_outside_value: "false"}) do
        summary_row
        body
      end
    end
  end

  private

  def summary_row
    summary(
      class: "flex cursor-pointer list-none select-none items-center gap-3 p-5 [&::-webkit-details-marker]:hidden",
      data: {action: "click->dropdown#toggle"}
    ) do
      render Components::Icon.new("compass", class: "size-5 flex-none text-accent-soft-fg")
      div(class: "min-w-0 flex-1") do
        p(class: "text-sm font-semibold text-text-primary") { t(".title") }
        p(class: "mt-0.5 text-xs text-text-muted") { t(".subtitle") }
      end
      render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
    end
  end

  def body
    div(class: "dropdown-menu border-t border-border-subtle p-5", data: {dropdown_target: "menu"}) do
      p(class: "text-sm text-text-secondary") { t(".intro") }
      div(class: "mt-4 flex flex-col gap-4") do
        item("at", t(".non_mentionable.title"), t(".non_mentionable.body"))
        item("sliders", t(".visibility.title"), t(".visibility.body"))
      end
    end
  end

  def item(icon, title, body)
    div(class: "flex gap-3 rounded-card bg-surface-sunken p-4") do
      render Components::Icon.new(icon, class: "mt-0.5 size-5 flex-none text-accent-soft-fg")
      div do
        p(class: "text-sm font-semibold text-text-primary") { title }
        p(class: "mt-1 text-sm text-text-secondary") { body }
      end
    end
  end
end
