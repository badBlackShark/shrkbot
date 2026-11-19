# frozen_string_literal: true

class Components::Moderation::ImageScanningResponseCard < Components::Base
  def initialize(action:, punishment:, timeout_seconds:, confirmed_punishment:, confirmed_timeout_seconds:)
    @action = action
    @punishment = punishment
    @timeout_seconds = timeout_seconds
    @confirmed_punishment = confirmed_punishment
    @confirmed_timeout_seconds = confirmed_timeout_seconds
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
        value: @action,
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
        value: @punishment,
        timeout_seconds: @timeout_seconds
      )
    end
  end

  def confirmed_punishment_field
    div do
      render Components::FieldLabel.new { t(".confirmed_punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "image_scanning[confirmed_punishment]",
        value: @confirmed_punishment,
        timeout_seconds: @confirmed_timeout_seconds,
        none_label: t(".confirmed_punishment.inherit")
      )
    end
  end
end
