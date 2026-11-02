# frozen_string_literal: true

class Views::Servers::Twitch::Show < Views::Servers::SubPluginShow
  private

  def plugin_key
    :twitch
  end

  def body
    render Components::Feeds::TwitchChannelList.new
  end
end
