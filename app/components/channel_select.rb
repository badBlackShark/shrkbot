# frozen_string_literal: true

class Components::ChannelSelect < Components::Base
  def initialize(name:, options:, placeholder:, selected: nil, include_blank: false, multiple: false)
    @name = name
    @options = options
    @placeholder = placeholder
    @selected = selected
    @include_blank = include_blank
    @multiple = multiple
  end

  def view_template
    render Components::TomSelect.new(
      name: @name,
      options: @options,
      selected: @selected,
      multiple: @multiple,
      include_blank: @include_blank,
      controller_data: {tom_select_prefix_value: "#", tom_select_placeholder_value: @placeholder}
    )
  end
end
