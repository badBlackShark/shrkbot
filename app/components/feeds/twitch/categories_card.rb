# frozen_string_literal: true

class Components::Feeds::Twitch::CategoriesCard < Components::Base
  FIELD_NAME = "subscription[categories][]"

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new(class: "flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".title") }
      div do
        render Components::FieldLabel.new { t(".label") }
        input(type: "hidden", name: FIELD_NAME, value: "", autocomplete: "off")
        render Components::TomSelect.new(
          name: FIELD_NAME,
          options:,
          selected: options.map(&:value),
          multiple: true,
          controller_data: {
            tom_select_search_url_value: server_twitch_categories_path(@subscription.server_configuration.discord_id),
            tom_select_placeholder_value: t(".placeholder"),
            tom_select_search_failed_value: t(".search_failed"),
            tom_select_max_items_value: ::Feeds::Twitch::Settings::MAX_CATEGORIES
          }
        )
        render Components::FieldHelp.new { t(".help") }
      end
      render Components::Feeds::Twitch::SwitchedAwayField.new(subscription: @subscription)
    end
  end

  private

  def options
    @options ||= @subscription.settings.categories.map do |category|
      Components::TomSelect::Option.for(value: ::Feeds::Twitch::CategoryValue.dump(category), label: category["name"])
    end
  end
end
