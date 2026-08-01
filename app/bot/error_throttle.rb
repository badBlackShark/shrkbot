# frozen_string_literal: true

module Bot
  class ErrorThrottle
    WINDOW = 5.minutes

    INSTANCE_MUTEX = Mutex.new

    def self.instance
      INSTANCE_MUTEX.synchronize { @instance ||= new }
    end

    def initialize
      @mutex = Mutex.new
      @windows = {}
    end

    def admit(key, at: Time.current)
      @mutex.synchronize do
        if throttled?(key, at)
          @windows[key][:suppressed] += 1
          nil
        else
          open_window(key, at)
        end
      end
    end

    private

    def throttled?(key, at)
      window = @windows[key]
      !window.nil? && window[:until] > at
    end

    def open_window(key, at)
      suppressed = @windows.dig(key, :suppressed) || 0
      @windows[key] = {until: at + WINDOW, suppressed: 0}
      suppressed
    end
  end
end
