# frozen_string_literal: true

class Components::Feeds::WatchImage < Components::Base
  SIZES = {md: "w-46", list: "w-30 sm:w-46"}.freeze
  SHAPE = "aspect-[460/215] flex-none rounded"

  def initialize(url:, size: :md, loading: "lazy")
    @url = url
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
    "#{SIZES.fetch(@size)} #{SHAPE}"
  end
end
