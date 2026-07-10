# frozen_string_literal: true

module Moderation
  module Punishable
    extend ActiveSupport::Concern

    included do
      enum :punishment, {none: "none", timeout: "timeout", kick: "kick", ban: "ban"}, prefix: true, validate: true
      validates :timeout_seconds,
        numericality: {only_integer: true, greater_than_or_equal_to: 60, less_than_or_equal_to: 2_419_200}
    end
  end
end
