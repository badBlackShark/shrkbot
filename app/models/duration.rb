# frozen_string_literal: true

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

  def about(seconds)
    minutes = [(seconds / 60.0).round, 1].max
    hours, rest = minutes.divmod(60)
    parts = []
    parts << "#{hours} h" if hours.positive?
    parts << "#{rest} min" if rest.positive? || hours.zero?
    "about #{parts.join(" ")}"
  end
end
