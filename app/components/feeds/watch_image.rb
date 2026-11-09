# frozen_string_literal: true

class Components::Feeds::WatchImage < Components::Base
  SHAPES = {
    steam: {shape: "aspect-[460/215] rounded", md: "w-46", list: "w-30 sm:w-46"},
    twitch: {shape: "aspect-square rounded-full", md: "w-22", list: "w-14 sm:w-22"}
  }.freeze

  def initialize(url:, plugin_key:, size: :md, loading: "lazy")
    @url = url
    @plugin_key = plugin_key
    @size = size
    @loading = loading
  end

  def view_template
    if @url
      img(src: @url, alt: "", loading: @loading, class: "#{css} object-cover")
    else
      div(class: "#{css} bg-surface-sunken")
    end
  end

  private

  def css
    shape = SHAPES.fetch(@plugin_key)
    "#{shape.fetch(@size)} #{shape.fetch(:shape)} flex-none"
  end
end
