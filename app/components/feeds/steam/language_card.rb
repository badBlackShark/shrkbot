# frozen_string_literal: true

class Components::Feeds::Steam::LanguageCard < Components::Base
  ENGLISH = "en"
  FIELD = "subscription[languages][]"

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new(class: "flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".title") }
      render Components::LiveWarning.new(
        fields: [FIELD],
        rule: "excludes-all",
        list: [ENGLISH],
        shown: english_left_out?
      ) { t(".note") }
      div do
        render Components::FieldLabel.new { t(".label") }
        input(type: "hidden", name: FIELD, value: "")
        render Components::TomSelect.new(
          name: FIELD,
          options:,
          selected: @subscription.settings.languages,
          multiple: true,
          controller_data: {tom_select_placeholder_value: t(".placeholder")}
        )
        render Components::FieldHelp.new { t(".help") }
      end
    end
  end

  private

  def english_left_out?
    languages = @subscription.settings.languages
    languages.any? && languages.exclude?(ENGLISH)
  end

  def options
    ::Integrations::Language::CODES
      .map { |code| Components::TomSelect::Option.for(value: code, label: t(".languages.#{code}")) }
      .sort_by(&:label)
  end
end
