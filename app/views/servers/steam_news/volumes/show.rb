# frozen_string_literal: true

class Views::Servers::SteamNews::Volumes::Show < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(volume:, plugin_key:)
    @volume = volume
    @plugin_key = plugin_key
  end

  def view_template
    turbo_frame_tag(Components::Feeds::VolumeLine::FRAME_ID) do
      render Components::Feeds::VolumeLine.new(volume: @volume, plugin_key: @plugin_key)
    end
  end
end
