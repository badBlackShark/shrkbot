# frozen_string_literal: true

module Feeds
  module SquareImage
    module_function

    def call(bytes)
      image = Vips::Image.new_from_buffer(bytes, "").colourspace(:srgb)
      image = image.bandjoin(255) unless image.has_alpha?
      side = [image.width, image.height].max
      image.gravity(:centre, side, side, extend: :background, background: [0, 0, 0, 0]).write_to_buffer(".webp", Q: 85)
    end
  end
end
