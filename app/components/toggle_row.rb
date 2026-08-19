# frozen_string_literal: true

class Components::ToggleRow < Components::Base
  def initialize(name:, checked:, label:, help: nil)
    @name = name
    @checked = checked
    @label = label
    @help = help
  end

  def view_template
    render Components::SettingRow.new(label: @label, help: @help) do
      render Components::Toggle.new(name: @name, checked: @checked, label: @label)
    end
  end
end
