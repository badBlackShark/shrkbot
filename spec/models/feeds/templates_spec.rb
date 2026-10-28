# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Templates do
  describe ".custom" do
    subject(:custom) { described_class.custom(text) }

    context "with text of its own" do
      let(:text) { "  Patch day: {game}  " }

      it { is_expected.to eq("Patch day: {game}") }
    end

    ["", "  ", nil].each do |blank|
      context "with #{blank.inspect}" do
        let(:text) { blank }

        it { is_expected.to be_nil }
      end
    end

    context "with only a non-breaking space" do
      let(:text) { "\u00A0 \u3000" }

      it { is_expected.to be_nil }
    end

    context "with text that equals the old default template" do
      let(:text) { "New {game} patch notes: {title}" }

      it { is_expected.to eq(text) }
    end
  end
end
