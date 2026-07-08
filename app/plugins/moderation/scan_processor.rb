# frozen_string_literal: true

require "net/http"
require "uri"

module Moderation
  module ScanProcessor
    module_function

    def call(context)
      bytes = download(context.attachment_url)
      result = Ocr::Client.new.scan(bytes)
      verdict = Classifier.call(
        ocr_text: result["text"],
        hash_state: :none,
        signals: context.signals,
        settings: context.settings
      )
      VerdictExecutor.call(verdict:, context:)
    rescue Ocr::Error => e
      Rails.logger.warn("[Moderation::ScanProcessor] scan failed: #{e.class}: #{e.message}")
    end

    def download(attachment_url)
      uri = URI(attachment_url)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 30
      ) do |http|
        response = http.get(uri)
        unless response.code.to_i.between?(200, 299)
          raise Ocr::Error, "attachment download failed: #{response.code}"
        end

        response.body
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      raise Ocr::Error, e.message
    end

    private_class_method :download
  end
end
