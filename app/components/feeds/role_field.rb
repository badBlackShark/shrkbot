# frozen_string_literal: true

class Components::Feeds::RoleField < Components::Base
  def initialize(subscription:, name:, selected:, label:, placeholder:)
    @subscription = subscription
    @name = name
    @selected = selected
    @label = label
    @placeholder = placeholder
  end

  def view_template
    render Components::FieldLabel.new { @label }
    render Components::RoleSelect.new(
      name: @name,
      options: ServerRoleOptions.new(@subscription.server_configuration).options,
      selected: @selected,
      placeholder: @placeholder,
      multiple: false,
      include_blank: true,
      data: {feed_preview_target: "role", action: "change->feed-preview#render"}
    )
  end
end
