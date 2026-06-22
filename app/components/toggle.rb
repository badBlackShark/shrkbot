# frozen_string_literal: true

class Components::Toggle < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(url:, checked:, label:, param: :enabled)
    @url = url
    @checked = checked
    @label = label
    @param = param
  end

  def view_template
    button_to(
      @url,
      method: :patch,
      params: {@param => !@checked},
      form: {class: "flex-none"},
      class: "toggle",
      role: "switch",
      aria: {checked: @checked.to_s, label: @label}
    ) { span(class: "toggle-knob") }
  end
end
