# frozen_string_literal: true

class Components::Feeds::TargetBanner < Components::Base
  def initialize(watch:, plugin_key:)
    @watch = watch
    @plugin_key = plugin_key
  end

  def view_template
    render Components::Feeds::TargetCard.new(target: @watch, plugin_key: @plugin_key) do
      render Components::Feeds::TargetSourceLink.new(url: @watch.url, plugin_key: @plugin_key)
    end
  end
end
