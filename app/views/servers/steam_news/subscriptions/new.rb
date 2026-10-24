# frozen_string_literal: true

class Views::Servers::SteamNews::Subscriptions::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(server_configuration:, user:, subscription:, target:, error: nil)
    @config = server_configuration
    @user = user
    @subscription = subscription
    @target = target
    @error = error
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: :steam_news) do
      render Components::Feeds::AddPage.new(server_configuration: @config, plugin_key: :steam_news) do
        render Components::Feeds::TargetCard.new(
          target: @target,
          plugin_key: :steam_news,
          change_href: new_server_steam_news_subscription_path(@config.discord_id)
        )
        follow_form
      end
    end
  end

  private

  def follow_form
    form_with(url: server_steam_news_subscriptions_path(@config.discord_id), class: "mt-5 flex flex-col gap-5") do
      input(type: "hidden", name: "subscription[external_id]", value: @target.external_id)
      render Components::Feeds::SubscriptionForm.new(subscription: @subscription, plugin_key: :steam_news, error: @error)
      actions
    end
  end

  def actions
    div(class: "flex justify-end gap-3") do
      render Components::Button.new(
        variant: :ghost,
        label: t(".cancel"),
        href: server_steam_news_path(@config.discord_id)
      )
      render Components::Button.new(label: t(".follow", name: @target.name), type: "submit")
    end
  end
end
