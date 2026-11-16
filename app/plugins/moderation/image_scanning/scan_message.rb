# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ScanMessage
      module_function

      def call(contexts)
        contexts.each do |context|
          break if ScanProcessor.call(context) == :remove
        rescue => e
          Rails.logger.error("[Moderation::ImageScanning::ScanMessage] scan crashed: #{e.class}: #{e.message}")
        end
      end
    end
  end
end
