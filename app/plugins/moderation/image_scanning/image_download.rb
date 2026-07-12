# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ImageDownload
      module_function

      def call(url)
        AttachmentDownload.call(url)
      rescue AttachmentDownload::Error => e
        raise Ocr::Error, e.message
      end
    end
  end
end
