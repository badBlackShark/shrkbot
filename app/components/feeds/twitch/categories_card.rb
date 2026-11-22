# frozen_string_literal: true

class Components::Feeds::Twitch::CategoriesCard < Components::Base
  FIELD_NAME = "subscription[categories][]"

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::Card.new(class: "group/categories flex flex-col gap-4") do
      h2(class: "font-semibold") { t(".title") }
      div do
        render Components::FieldLabel.new { t(".label") }
        input(type: "hidden", name: FIELD_NAME, value: "", autocomplete: "off")
        render Components::Feeds::Twitch::CategoryPicker.new(
          name: FIELD_NAME,
          server_configuration: @subscription.server_configuration,
          placeholder: t(".placeholder"),
          multiple: true,
          max_items: ::Feeds::Twitch::Settings::MAX_CATEGORIES,
          selected: @subscription.settings.categories
        )
        render Components::FieldHelp.new { t(".help") }
      end
      div(class: "hidden group-has-[option:checked]/categories:block") do
        render Components::Feeds::Twitch::SwitchedAwayField.new(subscription: @subscription)
      end
    end
  end
end
