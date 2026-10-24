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
      header
      cap_reason if at_cap?
      if subscriptions.empty?
        render Components::EmptyState.new(title: t(".#{@plugin_key}.empty_title"), body: t(".#{@plugin_key}.empty_body")) { add_button }
      else
        subscriptions.each { |subscription| subscription_row(subscription) }
      end
    end
  end

  private

  def header
    div(class: "flex flex-wrap items-center justify-between gap-3") do
      p(class: "text-[11px] font-semibold uppercase tracking-widest text-text-muted") { t(".#{@plugin_key}.heading") }
      add_button if subscriptions.any?
    end
  end

  def add_button
    return if @config.preview?

    if at_cap?
      render Components::Button.new(label: t(".#{@plugin_key}.add"), disabled: true, aria_describedby: CAP_REASON_ID)
    else
      render Components::Button.new(label: t(".#{@plugin_key}.add"), href: add_path)
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
      role_name: role_names[subscription.role_id],
      edit_href: (edit_path(subscription) unless @config.preview?)
    )
  end

  def add_path
    new_server_steam_news_subscription_path(@config.discord_id)
  end

  def edit_path(subscription)
    edit_server_steam_news_subscription_path(@config.discord_id, subscription)
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
    @channel_labels ||= ChannelOptions.new(@config).labels_by_id
  end

  def role_names
    @role_names ||= ServerRoleOptions.new(@config).names_by_id
  end
end
