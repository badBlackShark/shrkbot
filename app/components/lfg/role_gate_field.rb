# frozen_string_literal: true

class Components::Lfg::RoleGateField < Components::Base
  def initialize(name:, options:, selected:, label:, help:, placeholder:)
    @name = name
    @options = options
    @selected = selected
    @label = label
    @help = help
    @placeholder = placeholder
  end

  def view_template
    div do
      label(class: "mb-1.5 block text-sm font-semibold") { @label }
      render Components::RoleSelect.new(
        name: @name,
        options: @options,
        selected: @selected,
        placeholder: @placeholder
      )
      p(class: "mt-1.5 text-xs text-text-muted") { @help }
    end
  end
end
