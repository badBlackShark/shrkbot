# frozen_string_literal: true

class Components::RoleSelect < Components::Base
  def initialize(name:, options:, placeholder:, selected: [])
    @name = name
    @options = options
    @placeholder = placeholder
    @selected = selected
  end

  def view_template
    render Components::TomSelect.new(
      name: @name,
      options: @options,
      selected: @selected,
      multiple: true,
      controller_data: {tom_select_color_dots_value: true, tom_select_placeholder_value: @placeholder}
    )
  end
end
