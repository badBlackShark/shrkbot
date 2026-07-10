# frozen_string_literal: true

module Moderation
  module Punishable
    extend ActiveSupport::Concern

    included do
      string_enum :punishment, %w[none timeout kick ban], prefix: true
      validates :timeout_seconds,
        numericality: {only_integer: true, greater_than_or_equal_to: 60, less_than_or_equal_to: 2_419_200}
    end
  end
end
