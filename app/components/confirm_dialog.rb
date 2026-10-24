# frozen_string_literal: true

class Components::ConfirmDialog < Components::Base
  def view_template
    dialog(
      id: "confirm-dialog",
      role: "alertdialog",
      aria_labelledby: "confirm-dialog-title",
      aria_describedby: "confirm-dialog-body",
      class: "m-auto w-[calc(100%-2rem)] max-w-md rounded-card border border-border-default bg-surface-card p-6 text-text-primary shadow-lg backdrop:bg-surface-page/70 backdrop:backdrop-blur-[1px]"
    ) do
      form(method: "dialog", class: "flex flex-col gap-3") do
        h2(id: "confirm-dialog-title", class: "font-display text-lg font-bold tracking-tight")
        p(id: "confirm-dialog-body", class: "text-sm text-text-secondary")
        div(class: "mt-2 flex justify-end gap-2") do
          button(value: "cancel", autofocus: true, class: Components::Button.css(variant: :ghost)) { t(".cancel") }
          button(value: "confirm", id: "confirm-dialog-button", class: Components::Button.css(variant: :danger))
        end
      end
    end
  end
end
