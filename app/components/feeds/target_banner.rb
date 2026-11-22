# frozen_string_literal: true

class Components::Feeds::TargetBanner < Components::Base
  def initialize(watch:, source:)
    @watch = watch
    @source = source
  end

  def view_template
    render Components::Feeds::TargetCard.new(target: @watch, source: @source) do
      render Components::Feeds::TargetSourceLink.new(url: @watch.url, source: @source)
    end
  end
end
