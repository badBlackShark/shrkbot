# frozen_string_literal: true

class Views::Servers::SteamNews::Show < Views::Servers::SubPluginShow
  private

  def plugin_key
    :steam_news
  end

  def body
    group_subline
    render Components::Feeds::SubscriptionList.new(server_configuration: @config, plugin_key:)
  end
end
