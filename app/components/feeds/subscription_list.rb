# frozen_string_literal: true

class Components::Feeds::SubscriptionList < Components::Base
  CAP_REASON_ID = "feed-subscriptions-cap"

  def initialize(server_configuration:, source:)
    @config = server_configuration
    @source = source
  end

  def view_template
    render Components::ConfigSections.new(key: @source.key.to_s) do
      header if subscriptions.any?
      cap_reason if at_cap?
      if subscriptions.empty?
        render Components::EmptyState.new(title: t(".#{@source.key}.empty_title")) { add_button }
      else
        subscriptions.each { |subscription| subscription_row(subscription) }
      end
    end
  end

  private

  def header
    div(class: "flex flex-wrap items-center justify-between gap-3") do
      div(class: "flex items-center gap-2") do
        p(class: "text-[11px] font-semibold uppercase tracking-widest text-text-muted") { t(".#{@source.key}.heading") }
        span(class: "text-sm leading-none text-text-muted", aria_hidden: "true") { "•" }
        p(class: "text-xs tabular-nums text-text-muted") { t(".usage", used: subscriptions.size, max: ::Feeds::Subscription::MAX_PER_SOURCE) }
      end
      add_button
    end
  end

  def add_button
    return if @config.preview?

    if at_cap?
      render Components::Button.new(label: t(".#{@source.key}.add"), disabled: true, aria_describedby: CAP_REASON_ID)
    else
      render Components::Button.new(label: t(".#{@source.key}.add"), href: ::Feeds::SubscriptionPaths.new_for(@config, @source))
    end
  end

  def cap_reason
    p(id: CAP_REASON_ID, class: "text-sm text-text-secondary") do
      ::Feeds::Subscription.cap_message(@source)
    end
  end

  def subscription_row(subscription)
    render Components::Feeds::SubscriptionRow.new(
      subscription:,
      source: @source,
      labels: route_labels,
      edit_href: (::Feeds::SubscriptionPaths.edit_for(subscription) unless @config.preview?)
    )
  end

  def at_cap?
    return @at_cap if defined?(@at_cap)

    @at_cap = ::Feeds::Subscription.at_cap?(@config, @source)
  end

  def subscriptions
    @subscriptions ||= Finders::Feeds::SourceSubscriptions.call(
      server_configuration: @config,
      source: @source
    ).to_a
  end

  def route_labels
    @route_labels ||= ::Feeds::RouteLabels.new(@config)
  end
end
