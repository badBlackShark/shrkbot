module Reminders
  # Parses compact duration strings like "1d2h30m" into an ActiveSupport::Duration.
  module Duration
    UNITS = {"w" => :weeks, "d" => :days, "h" => :hours, "m" => :minutes, "s" => :seconds}.freeze
    PATTERN = /\A(\d+[wdhms])+\z/

    module_function

    def parse(str)
      normalized = str.to_s.strip.downcase
      return nil unless normalized.match?(PATTERN)

      total = normalized.scan(/(\d+)([wdhms])/).sum(0.seconds) do |amount, unit|
        amount.to_i.public_send(UNITS[unit])
      end
      total.zero? ? nil : total
    end
  end
end
