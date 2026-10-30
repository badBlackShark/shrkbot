# frozen_string_literal: true

class Components::Feeds::LanguageCard < Components::Base
  def initialize(subscription:, plugin_key:)
    @subscription = subscription
    @plugin_key = plugin_key
  end

  def view_template
    render Components::Card.new(class: "flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".title") }
      render Components::Callout.new(variant: :warning) { t(".#{@plugin_key}.note") }
      div do
        render Components::FieldLabel.new { t(".label") }
        input(type: "hidden", name: "subscription[languages][]", value: "")
        render Components::TomSelect.new(
          name: "subscription[languages][]",
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

  def options
    ::Integrations::Language::CODES
      .map { |code| Components::TomSelect::Option.for(value: code, label: t(".languages.#{code}")) }
      .sort_by(&:label)
  end
end
