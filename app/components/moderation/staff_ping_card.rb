# frozen_string_literal: true

class Components::Moderation::StaffPingCard < Components::Base
  def initialize(ping_staff:)
    @ping_staff = ping_staff
  end

  def view_template
    render Components::Card.new do
      div(class: "flex items-center justify-between max-w-md gap-4") do
        label(class: "text-sm font-semibold") { t(".label") }
        render Components::Toggle.new(
          name: "moderation[ping_staff]",
          checked: @ping_staff,
          label: t(".label"),
          size: :md
        )
      end
      p(class: "mt-1.5 text-xs text-text-muted max-w-md") { t(".help") }
    end
  end
end
