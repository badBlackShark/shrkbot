# frozen_string_literal: true

class Components::Feeds::ChannelField < Components::Base
  def initialize(subscription:, name:, selected:, label:, placeholder:, required: false)
    @subscription = subscription
    @name = name
    @selected = selected
    @label = label
    @placeholder = placeholder
    @required = required
  end

  def view_template
    render Components::FieldLabel.new { @label }
    render Components::ChannelSelect.new(
      name: @name,
      options: ChannelOptions.new(@subscription.server_configuration).options,
      selected: @selected,
      placeholder: @placeholder,
      include_blank: true,
      required: @required
    )
  end
end
