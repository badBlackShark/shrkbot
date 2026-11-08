# frozen_string_literal: true

class Components::Feeds::Twitch::RoleField < Components::Base
  def initialize(subscription:, event_type:)
    @subscription = subscription
    @event_type = event_type
  end

  def view_template
    div do
      render Components::FieldLabel.new { t(".role_label") }
      render Components::RoleSelect.new(
        name: "subscription[#{::Feeds::Twitch::Settings::ROLE_COLUMNS.fetch(@event_type)}]",
        options: ServerRoleOptions.new(@subscription.server_configuration).options,
        selected: @subscription.settings.role_id_for(@event_type),
        placeholder: t(".role_placeholder"),
        multiple: false,
        include_blank: true,
        data: {feed_preview_target: "role", action: "change->feed-preview#render"}
      )
    end
  end
end
