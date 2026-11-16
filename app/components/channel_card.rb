# frozen_string_literal: true

class Components::ChannelCard < Components::Base
  def initialize(name:, channels:, selected:, label:, required: false)
    @name = name
    @channels = channels
    @selected = selected
    @label = label
    @required = required
  end

  def view_template(&block)
    render Components::Card.new do
      render Components::FieldLabel.new do
        plain @label
        render Components::RequiredMarker.new if @required
      end
      if @channels.empty?
        p(class: "text-sm text-text-secondary") { t(".none") }
      else
        render Components::ChannelSelect.new(
          name: @name,
          options: @channels,
          selected: @selected,
          placeholder: t(".placeholder"),
          include_blank: true,
          required: @required
        )
      end
      yield if block
    end
  end
end
