# frozen_string_literal: true

class Components::Feeds::RoleField < Components::Base
  def initialize(subscription:, name:, selected:, label:, placeholder:, no_ping_label: nil)
    @subscription = subscription
    @name = name
    @selected = selected
    @label = label
    @placeholder = placeholder
    @no_ping_label = no_ping_label
  end

  def view_template
    render Components::FieldLabel.new { @label }
    render Components::RoleSelect.new(
      name: @name,
      options:,
      selected: @selected,
      placeholder: @placeholder,
      multiple: false,
      include_blank: true,
      data: {feed_preview_target: "role", action: "change->feed-preview#render"}
    )
  end

  private

  def options
    roles = ServerRoleOptions.new(@subscription.server_configuration).options
    return roles unless @no_ping_label

    [Components::TomSelect::Option.for(value: ::Feeds::Twitch::Settings::NO_PING, label: @no_ping_label), *roles]
  end
end
