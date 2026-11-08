# frozen_string_literal: true

class Views::Servers::Feeds::Subscriptions::Edit < Views::Base
  include Components::PluginNav

  def initialize(plugin_key:, server_configuration:, user:, subscription:)
    @plugin_key = plugin_key
    @config = server_configuration
    @user = user
    @subscription = subscription
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: @plugin_key) do
      render Components::ConfigPage.new(
        header:,
        server_configuration: @config,
        url: ::Feeds::SubscriptionPaths.for(@subscription),
        parent_crumb: {label: PluginCatalog.find(@plugin_key).name, href: PluginPaths.for(@config, @plugin_key)}
      ) do
        render Components::Feeds::SubscriptionForm.new(subscription: @subscription, plugin_key: @plugin_key)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon: plugin_icon(@plugin_key),
      title: @subscription.watch.name,
      description: t("components.feeds.target_card.#{@plugin_key}.external_id", id: @subscription.watch.external_id),
      media:
    )
  end

  def media
    image_url = @subscription.watch.image_url
    return unless image_url

    Components::Feeds::WatchImage.new(url: image_url, size: :list, loading: "eager")
  end
end
