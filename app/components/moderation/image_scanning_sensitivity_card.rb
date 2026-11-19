# frozen_string_literal: true

class Components::Moderation::ImageScanningSensitivityCard < Components::Base
  def initialize(sensitivity:)
    @sensitivity = sensitivity
  end

  def view_template
    render Components::Card.new do
      render Components::FieldLabel.new { t(".label") }
      render Components::SegmentedControl.new(
        name: "image_scanning[sensitivity]",
        value: @sensitivity,
        label: t(".label"),
        options: [
          {value: "relaxed", label: t(".relaxed")},
          {value: "standard", label: t(".standard")},
          {value: "strict", label: t(".strict")}
        ]
      )
      render Components::FieldHelp.new { t(".help") }
    end
  end
end
