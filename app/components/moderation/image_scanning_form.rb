# frozen_string_literal: true

class Components::Moderation::ImageScanningForm < Components::Base
  def initialize(context:)
    @settings = context.settings
  end

  def view_template
    render Components::ConfigSections.new(key: "image_scanning") do
      consent_callout
      report_scam_callout
      render Components::Moderation::ImageScanningSensitivityCard.new(sensitivity: @settings.sensitivity)
      render Components::Moderation::ImageScanningKeywordsCard.new(
        custom_keywords: @settings.custom_keywords,
        custom_keyword_min_hits: @settings.custom_keyword_min_hits
      )
      render Components::Moderation::ImageScanningResponseCard.new(
        action: @settings.action,
        punishment: @settings.punishment,
        timeout_seconds: @settings.timeout_seconds,
        confirmed_punishment: @settings.confirmed_punishment,
        confirmed_timeout_seconds: @settings.confirmed_timeout_seconds
      )
      render Components::Moderation::ImageScanningExplainer.new
    end
  end

  private

  def consent_callout
    render Components::Callout.new(variant: :warning) do
      div do
        p(class: "font-semibold") { t(".consent.title") }
        p(class: "mt-1") { t(".consent.body") }
      end
    end
  end

  def report_scam_callout
    render Components::Callout.new(variant: :info) do
      div do
        p(class: "font-semibold") { t(".report_scam.title") }
        p(class: "mt-1") { t(".report_scam.body") }
      end
    end
  end
end
