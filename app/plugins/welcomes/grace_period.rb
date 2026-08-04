# frozen_string_literal: true

module Welcomes
  class GracePeriod
    DURATION = 3

    def self.after(&block)
      Thread.new do
        sleep(DURATION)
        block.call
      rescue => e
        Rails.logger.error("[#{name}] #{e.class}: #{e.message}")
      end
    end
  end
end
