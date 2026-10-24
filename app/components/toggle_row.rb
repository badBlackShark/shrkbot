# frozen_string_literal: true

class Components::ToggleRow < Components::Base
  def initialize(name:, checked:, label:, help: nil, data: {})
    @name = name
    @checked = checked
    @label = label
    @help = help
    @data = data
  end

  def view_template
    render Components::SettingRow.new(label: @label, help: @help) do
      render Components::Toggle.new(name: @name, checked: @checked, label: @label, data: @data)
    end
  end
end
