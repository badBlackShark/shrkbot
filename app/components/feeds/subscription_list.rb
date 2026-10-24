# frozen_string_literal: true

class Components::Feeds::SubscriptionList < Components::Base
  def initialize(server_configuration:, plugin_key:, enable_error: nil)
    @config = server_configuration
    @plugin_key = plugin_key
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: @plugin_key.to_s, enable_error: @enable_error) do
      p(class: "text-[11px] font-semibold uppercase tracking-widest text-text-muted") { t(".heading") }
      if subscriptions.empty?
        render Components::EmptyState.new(title: t(".empty_title"), body: t(".empty_body")) { nil }
      else
        subscriptions.each { |subscription| subscription_row(subscription) }
      end
    end
  end

  private

  def subscription_row(subscription)
    render Components::Feeds::SubscriptionRow.new(
      subscription:,
      channel_label: channel_labels[subscription.channel_id],
      role_name: role_names[subscription.role_id]
    )
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
