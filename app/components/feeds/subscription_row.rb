# frozen_string_literal: true

class Components::Feeds::SubscriptionRow < Components::Base
  include Phlex::Rails::Helpers::L

  TITLE = "font-display font-semibold"

  def initialize(subscription:, plugin_key:, channel_label:, role_names:, edit_href: nil)
    @subscription = subscription
    @plugin_key = plugin_key
    @channel_label = channel_label
    @role_names = role_names
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
      if roles.shared?
        plain " - "
        plain ping_label
      end
    end
  end

  def ping_label
    role_id = roles.shared
    return t(".pings", role: @role_names[role_id]) if @role_names[role_id]
    return t(".role_missing") if role_id

    t(".no_ping")
  end

  def roles
    @roles ||= ::Feeds::SubscriptionRoles.new(@subscription)
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
        render Components::Badge.new(variant: :brand) { badge_label(event_type) }
      end
    end
  end

  def badge_label(event_type)
    label = t("components.feeds.event_types.#{::Feeds.event_key(event_type)}.label")
    return label if roles.shared?

    role_id = roles.for(event_type)
    return label unless role_id
    return t(".badge_role", type: label, role: @role_names[role_id]) if @role_names[role_id]

    t(".badge_role_missing", type: label, missing: t(".role_missing"))
  end

  def source
    ::Feeds.source(@plugin_key)
  end

  def event_types
    order = source.event_types
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
