# frozen_string_literal: true

class Components::ToggleRow < Components::Base
  def initialize(name:, checked:, label:, help: nil)
    @name = name
    @checked = checked
    @label = label
    @help = help
  end

  def view_template
    div(class: "flex items-center gap-4") do
      div(class: "flex-1") do
        p(class: "text-sm font-semibold") { @label }
        p(class: "mt-0.5 text-sm text-text-secondary") { @help } if @help
      end
      render Components::Toggle.new(name: @name, checked: @checked, label: @label)
    end
  end
end
