# frozen_string_literal: true

class Views::Servers::Feeds::Subscriptions::Edit < Views::Base
  def initialize(source:, server_configuration:, user:, subscription:)
    @source = source
    @config = server_configuration
    @user = user
    @subscription = subscription
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: @source.plugin_key) do
      render Components::ConfigPage.new(
        header:,
        server_configuration: @config,
        url: ::Feeds::SubscriptionPaths.for(@subscription),
        parent_crumb: {label: PluginCatalog.find(@source.plugin_key).name, href: PluginPaths.for(@config, @source.plugin_key)}
      ) do
        render Components::Feeds::SubscriptionForm.new(subscription: @subscription, source: @source)
      end
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      title: @subscription.watch.name,
      banner: Components::Feeds::TargetBanner.new(watch: @subscription.watch, source: @source)
    )
  end
end
