# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::Timestamp do
  describe ".relative" do
    subject(:relative) { described_class.relative(Time.utc(2026, 11, 6, 18, 0, 0)) }

    it "is Discord's relative timestamp of the epoch second" do
      expect(relative).to eq("<t:1793988000:R>")
    end
  end
end
