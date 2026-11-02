# frozen_string_literal: true

class Views::Servers::Twitch::Show < Views::Servers::SubPluginShow
  private

  def plugin_key
    :twitch
  end

  def body
    render Components::EmptyState.new(title: t(".empty_title"))
  end
end
