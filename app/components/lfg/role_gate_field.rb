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
      render Components::FieldLabel.new { @label }
      render Components::RoleSelect.new(
        name: @name,
        options: @options,
        selected: @selected,
        placeholder: @placeholder
      )
      render Components::FieldHelp.new { @help }
    end
  end
end
