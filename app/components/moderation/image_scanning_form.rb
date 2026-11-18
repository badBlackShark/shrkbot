# frozen_string_literal: true

class Components::Moderation::ImageScanningForm < Components::Base
  def initialize(context:, enable_error: nil)
    @settings = context.settings
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: "image_scanning", enable_error: @enable_error) do
      consent_callout
      report_scam_callout
      render Components::Moderation::ImageScanningSensitivityCard.new(settings: @settings)
      render Components::Moderation::ImageScanningKeywordsCard.new(settings: @settings)
      render Components::Moderation::ImageScanningResponseCard.new(settings: @settings)
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
