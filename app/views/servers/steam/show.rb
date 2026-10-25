# frozen_string_literal: true

class Views::Servers::Steam::Show < Views::Servers::SubPluginShow
  private

  def plugin_key
    :steam
  end

  def body
    render Components::Feeds::SubscriptionList.new(server_configuration: @config, plugin_key:)
  end
end
