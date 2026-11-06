# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Duration do
  describe ".about" do
    subject(:about) { described_class.about(seconds) }

    {
      11_520 => "about 3 h 12 min",
      3000 => "about 50 min",
      14_400 => "about 4 h",
      10 => "about 1 min",
      89 => "about 1 min",
      90 => "about 2 min"
    }.each do |value, expected|
      context "with #{value} seconds" do
        let(:seconds) { value }

        it { is_expected.to eq(expected) }
      end
    end
  end
end
