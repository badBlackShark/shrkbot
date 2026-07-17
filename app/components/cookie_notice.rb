# frozen_string_literal: true

class Components::CookieNotice < Components::Base
  def view_template
    div(
      hidden: true,
      data: {controller: "cookie-notice"},
      role: "status",
      class: "fixed inset-x-0 bottom-0 z-40 border-t border-border-default bg-surface-sunken px-4 py-3"
    ) do
      div(class: "mx-auto flex max-w-3xl flex-wrap items-center justify-center gap-x-4 gap-y-2") do
        p(class: "text-sm leading-relaxed text-text-primary") { t(".message") }
        render Components::Button.new(
          label: t(".dismiss"),
          variant: :secondary,
          size: :sm,
          data: {action: "cookie-notice#dismiss"}
        )
      end
    end
  end
end
