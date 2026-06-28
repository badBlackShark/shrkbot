# frozen_string_literal: true

class Components::SaveBar < Components::Base
  def view_template
    div(
      class: "save-bar fixed bottom-6 z-40 hidden w-[30rem] max-w-[calc(100vw-2.5rem)] rounded-xl",
      data: {save_bar_target: "bar"}
    ) do
      div(class: "flex items-center justify-between gap-6 rounded-xl border border-border-default bg-surface-card px-5 py-3 shadow-lg") do
        p(class: "flex items-center gap-2 text-sm text-text-secondary") do
          span(class: "size-2 flex-none rounded-full bg-warning")
          plain t(".unsaved")
        end
        div(class: "flex items-center gap-2") do
          render Components::Button.new(
            variant: :secondary,
            size: :sm,
            label: t(".discard"),
            data: {action: "save-bar#discard"}
          )
          render Components::Button.new(
            variant: :primary,
            size: :sm,
            type: "submit",
            icon: "check",
            label: t(".save")
          )
        end
      end
    end
    template(data: {save_bar_target: "discardedToast"}) do
      render Components::Toast.new(level: "notice", message: t(".discarded"))
    end
  end
end
