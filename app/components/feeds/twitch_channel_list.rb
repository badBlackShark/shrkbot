# frozen_string_literal: true

class Components::Feeds::TwitchChannelList < Components::Base
  def initialize(enable_error: nil)
    @enable_error = enable_error
  end

  def view_template
    render Components::ConfigSections.new(key: "twitch", enable_error: @enable_error) do
      render Components::EmptyState.new(title: t(".empty_title"))
    end
  end
end
