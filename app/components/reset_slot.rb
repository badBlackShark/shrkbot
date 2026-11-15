# frozen_string_literal: true

class Components::ResetSlot < Components::Base
  def initialize(label:, hidden:, slot_data:, data:)
    @label = label
    @hidden = hidden
    @slot_data = slot_data
    @data = data
  end

  def view_template
    span(class: "flex", hidden: @hidden, data: @slot_data) do
      render Components::ResetButton.new(label: @label, data: @data)
    end
  end
end
