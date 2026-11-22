# frozen_string_literal: true

class Views::Servers::Steam::Volumes::Show < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(volume:, source:)
    @volume = volume
    @source = source
  end

  def view_template
    turbo_frame_tag(Components::Feeds::VolumeLine::FRAME_ID) do
      render Components::Feeds::VolumeLine.new(volume: @volume, source: @source)
    end
  end
end
