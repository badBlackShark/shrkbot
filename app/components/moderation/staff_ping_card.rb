# frozen_string_literal: true

class Components::Moderation::StaffPingCard < Components::Base
  def initialize(ping_staff:)
    @ping_staff = ping_staff
  end

  def view_template
    render Components::Card.new do
      div(class: "flex items-center justify-between gap-4") do
        div(class: "max-w-md") do
          label(class: "text-sm font-semibold") { t(".label") }
          p(class: "mt-1.5 text-xs text-text-muted") { t(".help") }
        end
        render Components::Toggle.new(
          name: "moderation[ping_staff]",
          checked: @ping_staff,
          label: t(".label"),
          size: :md
        )
      end
    end
  end
end
