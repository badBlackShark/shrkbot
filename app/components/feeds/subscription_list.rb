# frozen_string_literal: true

class Components::Feeds::SubscriptionList < Components::Base
  CAP_REASON_ID = "feed-subscriptions-cap"

  def initialize(server_configuration:, plugin_key:, enable_error: nil)
    @config = server_configuration
    @plugin_key = plugin_key
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s, enable_error: @enable_error) do
      header if subscriptions.any?
      cap_reason if at_cap?
      if subscriptions.empty?
        render Components::EmptyState.new(title: t(".#{@plugin_key}.empty_title")) { add_button }
      else
        subscriptions.each { |subscription| subscription_row(subscription) }
      end
    end
  end

  private

  def header
    div(class: "flex flex-wrap items-center justify-between gap-3") do
      p(class: "text-[11px] font-semibold uppercase tracking-widest text-text-muted") { t(".#{@plugin_key}.heading") }
      add_button
    end
  end

  def add_button
    return if @config.preview?

    if at_cap?
      render Components::Button.new(label: t(".#{@plugin_key}.add"), disabled: true, aria_describedby: CAP_REASON_ID)
    else
      render Components::Button.new(label: t(".#{@plugin_key}.add"), href: ::Feeds::SubscriptionPaths.new_for(@config, @plugin_key))
    end
  end

  def cap_reason
    p(id: CAP_REASON_ID, class: "text-sm text-text-secondary") do
      t("operations.feeds.subscriptions.cap", max: ::Feeds::Subscription::MAX_PER_SERVER)
    end
  end

  def subscription_row(subscription)
    render Components::Feeds::SubscriptionRow.new(
      subscription:,
      plugin_key: @plugin_key,
      channel_label: channel_labels[subscription.channel_id],
      roles: role_names_for(subscription),
      edit_href: (::Feeds::SubscriptionPaths.edit_for(subscription) unless @config.preview?)
    )
  end

  def at_cap?
    return @at_cap if defined?(@at_cap)

    @at_cap = ::Feeds::Subscription.at_cap?(@config)
  end

  def subscriptions
    @subscriptions ||= Finders::Feeds::SourceSubscriptions.call(
      server_configuration: @config,
      plugin_key: @plugin_key
    ).to_a
  end

  def channel_labels
    @channel_labels ||= ChannelOptions.new(@config).qualified_labels_by_id
  end

  def role_names_for(subscription)
    subscription.role_ids.map { |id| role_names[id] }
  end

  def role_names
    @role_names ||= ServerRoleOptions.new(@config).names_by_id
  end
end
