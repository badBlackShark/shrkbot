# frozen_string_literal: true

class Components::Moderation::ImageScanningExplainer < Components::Base
  def view_template
    details(
      class: "rounded-card border border-border-default bg-surface-card shadow-sm overflow-hidden",
      data: {controller: "disclosure"}
    ) do
      summary(
        class: "flex cursor-pointer select-none list-none items-center gap-3 border-b border-border-subtle bg-surface-sunken px-5 py-3.5 [&::-webkit-details-marker]:hidden",
        data: {action: "click->disclosure#toggle"}
      ) do
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
        span(class: "text-sm font-semibold flex-1") { t(".title") }
      end
      div(class: "px-5 py-4") do
        ol(class: "list-decimal list-outside space-y-2.5 pl-5 marker:text-text-muted") do
          explainer_line(t(".line_memory"))
          explainer_line(t(".line_staff"))
          explainer_line(t(".line_fingerprint"))
        end
      end
    end
  end

  private

  def explainer_line(text)
    li(class: "text-sm text-text-secondary") { text }
  end
end
