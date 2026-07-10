# frozen_string_literal: true

module Moderation
  Reason = Data.define(:key, :weight, :detail) do
    def initialize(key:, weight:, detail: nil)
      super
    end
  end
end
