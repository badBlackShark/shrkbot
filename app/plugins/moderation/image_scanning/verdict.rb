# frozen_string_literal: true

module Moderation
  module ImageScanning
    Verdict = Data.define(:action, :risk, :reasons)
  end
end
