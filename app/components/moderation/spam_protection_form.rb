# frozen_string_literal: true

class Components::Moderation::SpamProtectionForm < Components::Base
  def initialize(context:, enable_error: nil)
    @settings = context.settings
    @enable_error = enable_error
  end

  def view_template
    div(id: "spam_protection-config", class: "flex flex-col gap-5") do
      enable_error_callout
      detection_card
      response_card
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def detection_card
    render Components::Card.new do
      div(class: "grid gap-5") do
        trigger_threshold_field
        match_strictness_field
        symbol_only_field
      end
    end
  end

  def trigger_threshold_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") do
        t(".detection.trigger_threshold.label")
      end
      div(class: "flex items-start gap-2.5 flex-wrap") do
        render Components::NumberStepper.new(
          name: "spam_protection[channel_threshold]",
          value: @settings.channel_threshold,
          min: 2,
          default: 4,
          unit: t(".detection.trigger_threshold.channels_unit")
        )
        span(class: "text-sm text-text-secondary h-8 inline-flex items-center") do
          t(".detection.trigger_threshold.within")
        end
        render Components::NumberStepper.new(
          name: "spam_protection[window_seconds]",
          value: @settings.window_seconds,
          min: 1,
          default: 15,
          unit: t(".detection.trigger_threshold.seconds_unit")
        )
      end
      p(class: "text-xs text-text-muted mt-1.5") { t(".detection.trigger_threshold.help") }
    end
  end

  def match_strictness_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".detection.match_strictness.label") }
      render Components::RangeSlider.new(
        name: "spam_protection[similarity]",
        value: @settings.similarity,
        label: t(".detection.match_strictness.label"),
        min_caption: t(".detection.match_strictness.min_caption"),
        max_caption: t(".detection.match_strictness.max_caption"),
        min: 75,
        max: 100
      )
      p(class: "text-xs text-text-muted mt-1.5") { t(".detection.match_strictness.help") }
      p(class: "text-xs text-text-muted mt-1") { t(".detection.match_strictness.recommended") }
    end
  end

  def symbol_only_field
    div do
      div(class: "flex items-center justify-between max-w-md gap-4") do
        label(class: "text-sm font-semibold") { t(".detection.symbol_only.label") }
        render Components::Toggle.new(
          name: "spam_protection[match_symbol_only_messages]",
          checked: @settings.match_symbol_only_messages,
          label: t(".detection.symbol_only.label"),
          size: :md
        )
      end
      p(class: "text-xs text-text-muted mt-1.5 max-w-md") { t(".detection.symbol_only.help") }
      p(class: "text-xs text-text-muted mt-1") { t(".detection.symbol_only.recommended") }
    end
  end

  def response_card
    render Components::Card.new do
      div(class: "grid gap-5") do
        action_field
        punishment_field
      end
    end
  end

  def action_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".response.action.label") }
      render Components::SegmentedControl.new(
        name: "spam_protection[action]",
        value: @settings.action,
        options: [
          {value: "purge", label: t(".response.action.purge")},
          {value: "notify_only", label: t(".response.action.notify_only")}
        ]
      )
      p(class: "text-xs text-text-muted mt-1.5") { t(".response.action.help") }
    end
  end

  def punishment_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".response.punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "spam_protection[punishment]",
        value: @settings.punishment,
        timeout_seconds: @settings.timeout_seconds
      )
    end
  end
end
