# frozen_string_literal: true

class Components::Feeds::TwitchCategory::LookupField < Components::Base
  def initialize(name:, value:, error_id:, server_configuration:)
    @name = name
    @value = value
    @error_id = error_id
    @config = server_configuration
  end

  def view_template
    render Components::Feeds::Twitch::CategoryPicker.new(
      name: @name,
      server_configuration: @config,
      placeholder: t(".placeholder"),
      multiple: false,
      max_items: 1,
      selected: [::Feeds::Twitch::CategoryValue.parse(@value)].compact,
      aria_label: t(".label"),
      error_id: @error_id
    )
  end
end
