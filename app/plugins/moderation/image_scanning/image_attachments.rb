# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ImageAttachments
      module_function

      def call(message)
        return [] unless message

        message.attachments.select { |attachment| CONTENT_TYPES.include?(attachment.content_type) }
      end
    end
  end
end
