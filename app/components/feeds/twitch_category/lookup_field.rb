# frozen_string_literal: true

class Components::Feeds::TwitchCategory::LookupField < Components::Base
  def initialize(name:, value:, server_configuration:, **)
    @name = name
    @value = value
    @config = server_configuration
  end

  def view_template
    render Components::TomSelect.new(
      name: @name,
      options:,
      selected: options.map(&:value),
      aria_label: t(".label"),
      controller_data: {
        tom_select_search_url_value: server_twitch_categories_path(@config.discord_id),
        tom_select_placeholder_value: t(".placeholder"),
        tom_select_search_failed_value: t(".search_failed"),
        tom_select_max_items_value: 1
      }
    )
  end

  private

  def options
    @options ||= [::Feeds::Twitch::CategoryValue.parse(@value)].compact.map do |category|
      Components::TomSelect::Option.for(value: ::Feeds::Twitch::CategoryValue.dump(category), label: category["name"])
    end
  end
end
