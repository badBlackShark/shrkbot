# frozen_string_literal: true

class Components::RoleSelect < Components::Base
  def initialize(name:, options:, placeholder:, selected: [], multiple: true, include_blank: false)
    @name = name
    @options = options
    @placeholder = placeholder
    @selected = selected
    @multiple = multiple
    @include_blank = include_blank
  end

  def view_template
    render Components::TomSelect.new(
      name: @name,
      options: @options,
      selected: @selected,
      multiple: @multiple,
      include_blank: @include_blank,
      controller_data: {
        tom_select_color_dots_value: true,
        tom_select_placeholder_value: @placeholder,
        tom_select_lock_icon_value: Components::Icon.new("lock", class: "size-3.5").call
      }
    )
  end
end
