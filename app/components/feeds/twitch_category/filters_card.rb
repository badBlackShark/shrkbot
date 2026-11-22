# frozen_string_literal: true

class Components::Feeds::TwitchCategory::FiltersCard < Components::Base
  LANGUAGES_FIELD = "subscription[languages][]"
  EXCLUDED_FIELD = "subscription[excluded_channels][]"

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new(class: "flex flex-col gap-5") do
      h2(class: "font-semibold") { t(".title") }
      render(Components::Callout.new(variant: :neutral)) { t(".top_streams") }
      min_viewers_field
      languages_field
      excluded_field
    end
  end

  private

  def settings
    @subscription.settings
  end

  def min_viewers_field
    div do
      render Components::InlineField.new(label: t(".min_viewers_label")) do
        render Components::NumberStepper.new(
          name: "subscription[min_viewers]",
          value: settings.min_viewers,
          label: t(".min_viewers_label"),
          min: 0,
          default: column_default(::Feeds::TwitchCategory::Settings, "min_viewers"),
          unit: t(".min_viewers_unit"),
          input_class: "w-16"
        )
      end
      render Components::FieldHelp.new { t(".min_viewers_help") }
    end
  end

  def languages_field
    div do
      render Components::FieldLabel.new { t(".languages_label") }
      input(type: "hidden", name: LANGUAGES_FIELD, value: "", autocomplete: "off")
      render Components::TomSelect.new(
        name: LANGUAGES_FIELD,
        options: language_options,
        selected: settings.languages,
        multiple: true,
        controller_data: {tom_select_placeholder_value: t(".languages_placeholder")}
      )
      render Components::FieldHelp.new { t(".languages_help") }
    end
  end

  def excluded_field
    div do
      render Components::FieldLabel.new { t(".excluded_label") }
      input(type: "hidden", name: EXCLUDED_FIELD, value: "", autocomplete: "off")
      render Components::TomSelect.new(
        name: EXCLUDED_FIELD,
        options: excluded_options,
        selected: settings.excluded_channels,
        multiple: true,
        controller_data: {tom_select_create_value: true, tom_select_placeholder_value: t(".excluded_placeholder")}
      )
      render Components::FieldHelp.new { t(".excluded_help") }
    end
  end

  def language_options
    ::Feeds::TwitchCategory::LANGUAGES
      .map { |code| Components::TomSelect::Option.for(value: code, label: t(".languages.#{code}")) }
      .sort_by(&:label)
  end

  def excluded_options
    settings.excluded_channels.map { |login| Components::TomSelect::Option.for(value: login, label: login) }
  end
end
