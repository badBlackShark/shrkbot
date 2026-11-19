# frozen_string_literal: true

class Components::Moderation::ImageScanningKeywordsCard < Components::Base
  def initialize(custom_keywords:, custom_keyword_min_hits:)
    @custom_keywords = custom_keywords
    @custom_keyword_min_hits = custom_keyword_min_hits
  end

  def view_template
    render Components::Card.new do
      div(class: "grid gap-5") do
        keywords_field
        min_hits_field
      end
    end
  end

  private

  def keywords_field
    div do
      render Components::FieldLabel.new { t(".keywords_label") }
      render Components::TomSelect.new(
        name: "image_scanning[custom_keywords][]",
        options: keyword_options,
        selected: @custom_keywords,
        multiple: true,
        controller_data: {
          tom_select_create_value: true,
          tom_select_placeholder_value: t(".keywords_placeholder")
        }
      )
      render Components::FieldHelp.new { t(".keywords_help") }
    end
  end

  def min_hits_field
    keyword_count = @custom_keywords.size
    max = keyword_count.positive? ? keyword_count : nil

    render Components::InlineField.new(label: t(".min_hits_label")) do
      render Components::NumberStepper.new(
        name: "image_scanning[custom_keyword_min_hits]",
        value: @custom_keyword_min_hits,
        min: 1,
        max:,
        default: ::Moderation::ImageScanning::Settings.column_defaults.fetch("custom_keyword_min_hits"),
        unit: t(".min_hits_unit")
      )
    end
  end

  def keyword_options
    @custom_keywords.map do |kw|
      Components::TomSelect::Option.for(value: kw, label: kw)
    end
  end
end
