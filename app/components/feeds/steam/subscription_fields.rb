# frozen_string_literal: true

class Components::Feeds::Steam::SubscriptionFields < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(subscription:)
    @subscription = subscription
  end

  def view_template
    div(class: "contents", data: {controller: "feed-preview"}) do
      render Components::Feeds::DestinationCard.new(subscription: @subscription)
      volume_frame
      event_types
      render Components::Feeds::Steam::LanguageCard.new(subscription: @subscription)
      render Components::Feeds::Steam::LengthCard.new(subscription: @subscription)
    end
  end

  private

  def event_types
    div do
      div(class: "flex flex-col gap-5") do
        render Components::Feeds::EventTypeList.new(subscription: @subscription, plugin_key: :steam)
      end
      render Components::Feeds::Steam::UpdateTypesNote.new(subscription: @subscription)
    end
  end

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
