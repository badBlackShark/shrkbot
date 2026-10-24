# frozen_string_literal: true

class Components::Feeds::WatchImage < Components::Base
  SIZES = {md: "w-46", sm: "w-30"}.freeze
  SHAPE = "aspect-[460/215] flex-none rounded"

  def initialize(url:, size: :md)
    @url = url
    @size = size
  end

  def view_template
    if @url
      img(src: @url, alt: "", loading: "lazy", class: "#{css} object-cover")
    else
      div(class: "#{css} bg-surface-sunken")
    end
  end

  private

  def css
    "#{SIZES.fetch(@size)} #{SHAPE}"
  end
end
