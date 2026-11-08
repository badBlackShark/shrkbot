# frozen_string_literal: true

class Components::Feeds::Twitch::ViewersToggle < Components::Base
  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    render Components::ToggleRow.new(
      name: "subscription[show_viewers]",
      checked: @subscription.settings.show_viewers,
      label: t(".label"),
      help: t(".help"),
      data: {viewers_toggle: true}
    )
  end
end
