# frozen_string_literal: true

class Components::Moderation::ImageScanningResponseCard < Components::Base
  def initialize(settings:)
    @settings = settings
  end

  def view_template
    render Components::Card.new do
      div(class: "grid gap-5") do
        action_field
        punishment_field
        confirmed_punishment_field
      end
    end
  end

  private

  def action_field
    div do
      render Components::FieldLabel.new { t(".action.label") }
      render Components::SegmentedControl.new(
        name: "image_scanning[action]",
        value: @settings.action,
        options: [
          {value: "delete", label: t(".action.delete")},
          {value: "none", label: t(".action.flag_only")}
        ]
      )
    end
  end

  def punishment_field
    div do
      render Components::FieldLabel.new { t(".punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "image_scanning[punishment]",
        value: @settings.punishment,
        timeout_seconds: @settings.timeout_seconds
      )
    end
  end

  def confirmed_punishment_field
    div do
      render Components::FieldLabel.new { t(".confirmed_punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "image_scanning[confirmed_punishment]",
        value: @settings.confirmed_punishment,
        timeout_seconds: @settings.confirmed_timeout_seconds,
        none_label: t(".confirmed_punishment.inherit")
      )
    end
  end
end
