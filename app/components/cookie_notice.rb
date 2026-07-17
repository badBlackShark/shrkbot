# frozen_string_literal: true

class Components::CookieNotice < Components::Base
  def view_template
    div(
      hidden: true,
      data: {controller: "cookie-notice"},
      role: "status",
      class: "fixed bottom-6 left-1/2 z-40 w-[40rem] max-w-[calc(100vw-2.5rem)] -translate-x-1/2 rounded-xl"
    ) do
      div(class: "flex flex-col gap-3 rounded-xl border border-border-default bg-surface-card px-5 py-3 shadow-lg sm:flex-row sm:items-center sm:justify-between sm:gap-6") do
        p(class: "text-sm leading-relaxed text-text-secondary") { t(".message") }
        render Components::Button.new(
          label: t(".dismiss"),
          variant: :primary,
          size: :sm,
          class: "flex-none self-end whitespace-nowrap sm:self-auto",
          data: {action: "cookie-notice#dismiss"}
        )
      end
    end
  end
end
