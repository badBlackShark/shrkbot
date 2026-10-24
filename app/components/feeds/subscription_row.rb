# frozen_string_literal: true

class Components::Feeds::SubscriptionRow < Components::Base
  include Phlex::Rails::Helpers::L

  def initialize(subscription:, channel_label:, role_name:)
    @subscription = subscription
    @channel_label = channel_label
    @role_name = role_name
  end

  def view_template
    render Components::Card.new(enabled: true, class: "flex flex-wrap items-center gap-4") do
      div(class: "min-w-0 flex-1") do
        span(class: "font-display font-semibold") { watch.name }
        meta
      end
      event_badges
      broken_callout if watch.broken?
    end
  end

  private

  def watch
    @subscription.watch
  end

  def meta
    p(class: "mt-0.5 text-sm text-text-secondary") do
      channel
      plain " - "
      plain ping_label
    end
  end

  def ping_label
    return t(".pings", role: @role_name) if @role_name
    return t(".role_missing") if @subscription.role_id

    t(".no_ping")
  end

  def channel
    if @channel_label
      span(class: "font-mono text-xs") { @channel_label }
    else
      plain t(".channel_missing")
    end
  end

  def event_badges
    div(class: "flex flex-wrap gap-1.5") do
      event_types.each do |event_type|
        render Components::Badge.new(variant: :brand) { t(".event_types.#{event_type.demodulize.underscore}") }
      end
    end
  end

  def event_types
    @subscription.subscribed_events.map(&:event_type).sort_by { |event_type| ::Feeds::EVENT_TYPES.index(event_type) }
  end

  def broken_callout
    render Components::Callout.new(variant: :warning, class: "w-full") do
      t(".broken", since: l(watch.failing_since, format: :long))
    end
  end
end
