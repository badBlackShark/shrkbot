# frozen_string_literal: true

class Components::Feeds::Steam::SubscriptionFields < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      render(Components::Feeds::DestinationCard.new(subscription: @subscription)) do
        div(class: "flex-1 basis-64") do
          render Components::Feeds::RoleField.new(
            subscription: @subscription,
            name: "subscription[role_id]",
            selected: @subscription.settings.role_id
          )
        end
      end
      render(Components::Feeds::EventTypesCard.new(subscription: @subscription, plugin_key: :steam)) do
        volume_frame
        render Components::Feeds::Steam::UpdateTypesNote.new(subscription: @subscription)
      end
      render Components::Feeds::Steam::LanguageCard.new(subscription: @subscription)
      render Components::Feeds::Steam::LengthCard.new(subscription: @subscription)
    end
  end

  private

  def volume_frame
    turbo_frame_tag(
      Components::Feeds::VolumeLine::FRAME_ID,
      src: ::Feeds::SubscriptionPaths.volume_for(@subscription),
      loading: "lazy"
    ) do
      render Components::Callout.new(variant: :info, icon: Components::Feeds::VolumeLine::ICON) { t(".volume_loading") }
    end
  end
end
