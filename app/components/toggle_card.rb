# frozen_string_literal: true

class Components::ToggleCard < Components::Base
  def initialize(name:, checked:, label:, help: nil)
    @name = name
    @checked = checked
    @label = label
    @help = help
  end

  def view_template
    render Components::Card.new do
      render Components::ToggleRow.new(name: @name, checked: @checked, label: @label, help: @help)
    end
  end
end
