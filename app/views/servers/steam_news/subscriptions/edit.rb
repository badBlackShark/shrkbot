# frozen_string_literal: true

class Views::Servers::SteamNews::Subscriptions::Edit < Views::Base
  include Components::PluginNav

  def initialize(server_configuration:, user:, subscription:, volume: nil)
    @config = server_configuration
    @user = user
    @subscription = subscription
    @volume = volume
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :steam_news) do
      render Components::ConfigPage.new(
        header:,
        server_configuration: @config,
        url: ::Feeds::SubscriptionPaths.for(@subscription),
        parent_crumb: {label: PluginCatalog.find(:steam_news).name, href: server_steam_news_path(@config.discord_id)},
        header_media: Components::Feeds::WatchImage.new(url: @subscription.watch.image_url, size: :md)
      ) do
        render Components::Feeds::SubscriptionForm.new(subscription: @subscription, plugin_key: :steam_news, volume: @volume)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon: plugin_icon(:steam_news),
      title: @subscription.watch.name,
      description: t("components.feeds.target_card.steam_news.external_id", id: @subscription.watch.external_id)
    )
  end
end
