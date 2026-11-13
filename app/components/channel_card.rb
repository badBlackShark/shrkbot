# frozen_string_literal: true

class Components::ChannelCard < Components::Base
  def initialize(name:, channels:, selected:, label:, help:, required: false, **attrs)
    @name = name
    @channels = channels
    @selected = selected
    @label = label
    @help = help
    @required = required
    @attrs = attrs
  end

  def view_template(&block)
    render Components::Card.new(**@attrs) do
      label(class: "block text-sm font-semibold") do
        plain @label
        render Components::RequiredMarker.new if @required
      end
      p(class: "mb-2 mt-0.5 text-sm text-text-secondary") { @help }
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
