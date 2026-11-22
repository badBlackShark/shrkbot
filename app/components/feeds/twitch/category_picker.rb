# frozen_string_literal: true

class Components::Feeds::Twitch::CategoryPicker < Components::Base
  def initialize(name:, server_configuration:, placeholder:, multiple:, max_items:, selected: [], aria_label: nil, error_id: nil)
    @name = name
    @config = server_configuration
    @placeholder = placeholder
    @multiple = multiple
    @max_items = max_items
    @selected = selected
    @aria_label = aria_label
    @error_id = error_id
  end

  def view_template
    render Components::TomSelect.new(
      name: @name,
      options:,
      selected: options.map(&:value),
      multiple: @multiple,
      aria_label: @aria_label,
      aria_invalid: !@error_id.nil?,
      aria_describedby: @error_id,
      controller_data: {
        tom_select_search_url_value: server_twitch_categories_path(@config.discord_id),
        tom_select_placeholder_value: @placeholder,
        tom_select_search_failed_value: t(".search_failed"),
        tom_select_max_items_value: @max_items
      }
    )
  end

  private

  def options
    @options ||= @selected.map do |category|
      Components::TomSelect::Option.for(value: ::Feeds::Twitch::CategoryValue.dump(category), label: category["name"])
    end
  end
end
