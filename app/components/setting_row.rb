# frozen_string_literal: true

class Components::SettingRow < Components::Base
  def initialize(label:, help: nil)
    @label = label
    @help = help
  end

  def view_template
    div(class: "flex items-center gap-4") do
      div(class: "flex-1") do
        p(class: "text-sm font-semibold") { @label }
        p(class: "mt-0.5 text-sm text-text-secondary") { @help } if @help
      end
      yield
    end
  end
end
