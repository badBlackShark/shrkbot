# frozen_string_literal: true

class Components::Moderation::PunishmentControl < Components::Base
  DURATION_OPTIONS = [
    {seconds: 300, label: "5 minutes"},
    {seconds: 600, label: "10 minutes"},
    {seconds: 1_800, label: "30 minutes"},
    {seconds: 3_600, label: "1 hour"},
    {seconds: 7_200, label: "2 hours"},
    {seconds: 21_600, label: "6 hours"},
    {seconds: 43_200, label: "12 hours"},
    {seconds: 86_400, label: "1 day"},
    {seconds: 604_800, label: "7 days"},
    {seconds: 2_419_200, label: "28 days"}
  ].freeze

  def initialize(name:, value:, timeout_seconds:)
    @name = name
    @value = value.to_s
    @timeout_seconds = timeout_seconds
  end

  def view_template
    div(data: {controller: "punishment"}) do
      render Components::SegmentedControl.new(
        name: @name,
        value: @value,
        options: [
          {value: "none", label: t("components.moderation.punishment_control.none")},
          {value: "timeout", label: t("components.moderation.punishment_control.timeout")},
          {value: "kick", label: t("components.moderation.punishment_control.kick")},
          {value: "ban", label: t("components.moderation.punishment_control.ban")}
        ]
      )
      duration_block
      ban_warning
    end
  end

  private

  def duration_block
    div(
      class: "mt-3",
      data: {punishment_target: "duration"},
      hidden: @value != "timeout"
    ) do
      label(class: "block text-xs font-semibold mb-1.5") do
        t("components.moderation.punishment_control.duration_label")
      end
      render Components::TomSelect.new(
        name: timeout_field_name,
        options: duration_options,
        selected: @timeout_seconds
      )
      p(class: "text-xs text-text-muted mt-1.5") do
        t("components.moderation.punishment_control.duration_help")
      end
    end
  end

  def ban_warning
    div(
      data: {punishment_target: "banWarning"},
      hidden: @value != "ban"
    ) do
      render Components::Callout.new(variant: :danger, class: "mt-3") do
        t("components.moderation.punishment_control.ban_warning")
      end
    end
  end

  def duration_options
    DURATION_OPTIONS.map do |opt|
      Components::TomSelect::Option.for(
        value: opt[:seconds],
        label: opt[:label]
      )
    end
  end

  def timeout_field_name
    @name.sub(/punishment\]$/, "timeout_seconds]")
  end
end
