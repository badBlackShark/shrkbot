# frozen_string_literal: true

class Components::ConfirmDialog < Components::Base
  def view_template
    dialog(
      id: "confirm-dialog",
      aria_labelledby: "confirm-dialog-title",
      aria_describedby: "confirm-dialog-body",
      data: {default_title: t(".title"), default_button: t(".button")},
      class: "m-auto w-[calc(100%-2rem)] max-w-md rounded-xl border border-border-default bg-surface-raised p-6 text-text-primary shadow-lg backdrop:bg-black/55"
    ) do
      form(method: "dialog", class: "flex flex-col gap-3") do
        h2(id: "confirm-dialog-title", class: "font-display text-lg font-bold tracking-tight")
        p(id: "confirm-dialog-body", class: "text-sm text-text-secondary")
        div(class: "mt-2 flex justify-end gap-2") do
          button(value: "cancel", autofocus: true, class: Components::Button.css(variant: :ghost)) { t(".cancel") }
          button(value: "confirm", id: "confirm-dialog-button", class: Components::Button.css(variant: :danger)) { t(".button") }
        end
      end
    end
  end
end
