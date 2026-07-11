# frozen_string_literal: true

class Components::Moderation::ImageScanningForm < Components::Base
  def initialize(context:, enable_error: nil)
    @settings = context.settings
    @enable_error = enable_error
  end

  def view_template
    div(id: "image_scanning-config", class: "flex flex-col gap-5") do
      enable_error_callout
      consent_callout
      sensitivity_card
      custom_keywords_card
      response_card
      image_explainer
      report_scam_hint
    end
  end

  private

  def enable_error_callout
    return unless @enable_error

    render Components::Callout.new(variant: :danger) { @enable_error }
  end

  def consent_callout
    render Components::Callout.new(variant: :warning) do
      div do
        p(class: "font-semibold") { t(".consent.title") }
        p(class: "mt-1") { t(".consent.body") }
      end
    end
  end

  def sensitivity_card
    render Components::Card.new do
      label(class: "block text-sm font-semibold mb-1.5") { t(".detection.sensitivity.label") }
      render Components::RadioCardGroup.new(
        name: "image_scanning[sensitivity]",
        value: @settings.sensitivity,
        label: t(".detection.sensitivity.label"),
        options: [
          {
            value: "relaxed",
            title: t(".detection.sensitivity.relaxed_title"),
            description: t(".detection.sensitivity.relaxed_description")
          },
          {
            value: "standard",
            title: t(".detection.sensitivity.standard_title"),
            description: t(".detection.sensitivity.standard_description")
          },
          {
            value: "strict",
            title: t(".detection.sensitivity.strict_title"),
            description: t(".detection.sensitivity.strict_description")
          }
        ]
      )
    end
  end

  def custom_keywords_card
    render Components::Card.new do
      div(class: "grid gap-5") do
        keywords_field
        min_hits_field
      end
    end
  end

  def keywords_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".custom_keywords.keywords_label") }
      render Components::TomSelect.new(
        name: "image_scanning[custom_keywords][]",
        options: keyword_options,
        selected: @settings.custom_keywords,
        multiple: true,
        controller_data: {tom_select_create_value: true}
      )
      p(class: "text-xs text-text-muted mt-1.5") { t(".custom_keywords.keywords_help") }
    end
  end

  def min_hits_field
    keyword_count = @settings.custom_keywords.size
    max = keyword_count.positive? ? keyword_count : nil

    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".custom_keywords.min_hits_label") }
      div(class: "flex items-start gap-2.5") do
        render Components::NumberStepper.new(
          name: "image_scanning[custom_keyword_min_hits]",
          value: @settings.custom_keyword_min_hits,
          min: 1,
          default: 2,
          max:
        )
        span(class: "text-sm text-text-secondary h-10 inline-flex items-center") do
          t(".custom_keywords.min_hits_suffix")
        end
      end
      p(class: "text-xs text-text-muted mt-1.5") { t(".custom_keywords.min_hits_help") }
    end
  end

  def response_card
    render Components::Card.new do
      div(class: "grid gap-5") do
        action_field
        punishment_field
        confirmed_punishment_field
      end
    end
  end

  def action_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".response.action.label") }
      render Components::SegmentedControl.new(
        name: "image_scanning[action]",
        value: @settings.action,
        options: [
          {value: "delete", label: t(".response.action.delete")},
          {value: "none", label: t(".response.action.flag_only")}
        ]
      )
      p(class: "text-xs text-text-muted mt-1.5") { t(".response.action.help") }
    end
  end

  def punishment_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".response.punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "image_scanning[punishment]",
        value: @settings.punishment,
        timeout_seconds: @settings.timeout_seconds
      )
    end
  end

  def confirmed_punishment_field
    div do
      label(class: "block text-sm font-semibold mb-1.5") { t(".response.confirmed_punishment.label") }
      render Components::Moderation::PunishmentControl.new(
        name: "image_scanning[confirmed_punishment]",
        value: @settings.confirmed_punishment,
        timeout_seconds: @settings.confirmed_timeout_seconds,
        none_label: t(".response.confirmed_punishment.inherit")
      )
      p(class: "text-xs text-text-muted mt-1.5") { t(".response.confirmed_punishment.help") }
    end
  end

  def image_explainer
    details(
      class: "rounded-card border border-border-default bg-surface-card shadow-sm overflow-hidden",
      data: {controller: "dropdown", dropdown_dismiss_on_outside_value: "false"}
    ) do
      summary(
        class: "flex cursor-pointer select-none list-none items-center gap-3 border-b border-border-subtle bg-surface-sunken px-5 py-3.5 [&::-webkit-details-marker]:hidden",
        data: {action: "click->dropdown#toggle"}
      ) do
        render Components::Icon.new("caret-down", class: "dropdown-chevron size-4 text-text-muted")
        span(class: "text-sm font-semibold flex-1") { t(".explainer.title") }
      end
      div(
        class: "dropdown-menu grid gap-3 px-5 py-4",
        data: {dropdown_target: "menu"}
      ) do
        explainer_line("cpu", t(".explainer.line_memory"))
        explainer_line("check-square", t(".explainer.line_staff"))
        explainer_line("fingerprint", t(".explainer.line_fingerprint"))
      end
    end
  end

  def explainer_line(icon, text)
    p(class: "flex items-start gap-2.5 text-sm text-text-secondary") do
      render Components::Icon.new(icon, class: "size-4 mt-0.5 text-text-muted flex-none")
      span { text }
    end
  end

  def report_scam_hint
    p(class: "mt-2 flex items-center gap-1.5 text-xs text-text-muted") do
      render Components::Icon.new("terminal-window", class: "size-4")
      span { t(".report_scam_hint") }
    end
  end

  def keyword_options
    @settings.custom_keywords.map do |kw|
      Components::TomSelect::Option.for(value: kw, label: kw)
    end
  end
end
