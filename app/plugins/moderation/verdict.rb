# frozen_string_literal: true

module Moderation
  Verdict = Data.define(:action, :risk, :reasons)
end
