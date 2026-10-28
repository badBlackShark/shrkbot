# frozen_string_literal: true

# Steam artwork is remote input. Untrusted loaders (ImageMagick, MATLAB, ...) are libvips' riskiest.
Vips.block_untrusted(true)
