# frozen_string_literal: true

class Components::Moderation::MatchingExplainer < Components::Base
  def view_template
    div(
      id: "matching",
      class: "overflow-hidden rounded-card border border-border-default bg-surface-card shadow-sm"
    ) do
      details(
        data: {controller: "dropdown", dropdown_dismiss_on_outside_value: "false"}
      ) do
        summary(
          class: "flex cursor-pointer list-none select-none items-center gap-3 bg-surface-sunken border-b border-border-subtle px-5 py-3.5 [&::-webkit-details-marker]:hidden",
          data: {action: "click->dropdown#toggle"}
        ) do
          render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 flex-none text-text-muted")
          span(class: "flex-1 text-sm font-semibold") { t(".title") }
        end
        div(
          class: "dropdown-menu grid gap-3 px-5 py-4",
          data: {dropdown_target: "menu"}
        ) do
          explainer_row(t(".row_normalize"))
          explainer_row(t(".row_lookalike"))
          explainer_row(t(".row_spam"))
          explainer_row(t(".row_keywords"))
        end
      end
    end
  end

  private

  def explainer_row(text)
    p(class: "text-sm text-text-secondary") { text }
  end
end
