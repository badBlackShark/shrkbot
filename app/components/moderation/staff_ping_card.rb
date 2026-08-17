# frozen_string_literal: true

class Components::Moderation::StaffPingCard < Components::Base
  def initialize(ping_staff:)
    @ping_staff = ping_staff
  end

  def view_template
    render Components::Card.new do
      render Components::SettingRow.new(label: t(".label"), help: t(".help")) do
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
