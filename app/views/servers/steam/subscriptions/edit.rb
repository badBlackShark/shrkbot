# frozen_string_literal: true

class Views::Servers::Steam::Subscriptions::Edit < Views::Base
  include Components::PluginNav

  def initialize(server_configuration:, user:, subscription:)
    @config = server_configuration
    @user = user
    @subscription = subscription
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :steam) do
      render Components::ConfigPage.new(
        header:,
        server_configuration: @config,
        url: ::Feeds::SubscriptionPaths.for(@subscription),
        parent_crumb: {label: PluginCatalog.find(:steam).name, href: server_steam_path(@config.discord_id)}
      ) do
        render Components::Feeds::SubscriptionForm.new(subscription: @subscription, plugin_key: :steam)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon: plugin_icon(:steam),
      title: @subscription.watch.name,
      description: t("components.feeds.target_card.steam.external_id", id: @subscription.watch.external_id),
      media:
    )
  end

  def media
    image_url = @subscription.watch.image_url
    return unless image_url

    Components::Feeds::WatchImage.new(url: image_url, size: :list, loading: "eager")
  end
end
