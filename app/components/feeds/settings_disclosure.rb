# frozen_string_literal: true

class Components::Feeds::SettingsDisclosure < Components::Base
  SUMMARY = "flex cursor-pointer list-none select-none items-center gap-1.5 text-sm font-medium " \
    "text-text-secondary [&::-webkit-details-marker]:hidden"

  def view_template(&)
    details(data: {disclosure_target: "details"}) do
      summary(class: SUMMARY, data: {action: "click->disclosure#toggle"}) do
        span { t(".summary") }
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-3.5 flex-none text-text-muted")
      end
      div(class: "mt-3 flex flex-col gap-3", &)
    end
  end
end
