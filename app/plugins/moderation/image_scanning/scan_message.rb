# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ScanMessage
      module_function

      def call(contexts)
        silent = false
        contexts.each do |context|
          action = ScanProcessor.call(context.with(silent:))
          break if action == :remove

          silent ||= action == :flag_for_review
        rescue => e
          Rails.logger.error("[Moderation::ImageScanning::ScanMessage] scan crashed on message #{context.message_id}: #{e.class}: #{e.message}")
        end
      end
    end
  end
end
