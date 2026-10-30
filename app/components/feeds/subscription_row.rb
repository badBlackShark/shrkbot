# frozen_string_literal: true

class Components::Feeds::SubscriptionRow < Components::Base
  include Phlex::Rails::Helpers::L

  TITLE = "font-display font-semibold"

  def initialize(subscription:, plugin_key:, channel_label:, role_name:, edit_href: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @channel_label = channel_label
    @role_name = role_name
    @edit_href = edit_href
  end

  def view_template
    render Components::Card.new(enabled: true, lift: linked?, class: "relative flex flex-wrap items-center gap-4") do
      render Components::Feeds::WatchImage.new(url: watch.image_url, size: :list)
      div(class: "min-w-0 flex-1") do
        title
        meta
        event_badges
      end
      stop_following if linked?
      broken_callout if watch.broken?
    end
  end

  private

  def linked?
    !@edit_href.nil?
  end

  def watch
    @subscription.watch
  end

  def title
    if linked?
      a(href: @edit_href, class: "#{TITLE} block after:absolute after:inset-0 after:rounded-card focus-visible:outline-none focus-visible:after:ring-3 focus-visible:after:ring-[var(--focus-ring)]") { watch.name }
    else
      p(class: TITLE) { watch.name }
    end
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
    div(class: "mt-3 flex flex-wrap gap-1.5") do
      event_types.each do |event_type|
        render Components::Badge.new(variant: :brand) { t("components.feeds.event_types.#{::Feeds.event_key(event_type)}.label") }
      end
    end
  end

  def event_types
    order = ::Feeds.source(@plugin_key).event_types
    @subscription.subscribed_events.map(&:event_type).sort_by { |event_type| order.index(event_type) }
  end

  def stop_following
    div(class: "relative z-10 self-start") do
      render Components::Feeds::StopFollowingButton.new(subscription: @subscription, compact: true)
    end
  end

  def broken_callout
    render Components::Callout.new(variant: :warning, class: "w-full") do
      t(".#{@plugin_key}.broken", since: l(watch.failing_since, format: :long))
    end
  end
end
