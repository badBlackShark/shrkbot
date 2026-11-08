# frozen_string_literal: true

class Components::Feeds::Steam::RoleField < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "flex-1 basis-64") do
      render Components::FieldLabel.new { t(".role_label") }
      render Components::RoleSelect.new(
        name: "subscription[role_id]",
        options: ServerRoleOptions.new(@subscription.server_configuration).options,
        selected: @subscription.settings.role_id,
        placeholder: t(".role_placeholder"),
        multiple: false,
        include_blank: true,
        data: {feed_preview_target: "role", action: "change->feed-preview#render"}
      )
    end
  end
end
