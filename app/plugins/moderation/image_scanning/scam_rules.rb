# frozen_string_literal: true

module Moderation
  module ImageScanning
    module ScamRules
      RULES = [
        {pattern: "tuzawin", weight: 3, regex: false},
        {pattern: "atomage.cc", weight: 3, regex: false},
        {pattern: "5[\\s,]?600", weight: 3, regex: true},
        {pattern: "2[\\s,]?500 bonus", weight: 3, regex: true},
        {pattern: "cryptocurrency", weight: 3, regex: false},
        {pattern: "crypto casino", weight: 3, regex: false},
        {pattern: "promo code", weight: 3, regex: false},
        {pattern: "usdt", weight: 3, regex: false},
        {pattern: "withdrawal success", weight: 3, regex: false},
        {pattern: "tether", weight: 3, regex: false},
        {pattern: "vyro", weight: 2, regex: false},
        {pattern: "casino", weight: 2, regex: false},
        {pattern: "wallet address", weight: 2, regex: false},
        {pattern: "receive usdt", weight: 2, regex: false},
        {pattern: "withdraw", weight: 2, regex: false}
      ].freeze
    end
  end
end
