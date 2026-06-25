# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discord::Truncate do
  describe ".call" do
    subject(:truncated) { described_class.call(text, limit) }

    context "when the text fits within the limit" do
      let(:text) { "hello world" }
      let(:limit) { 50 }

      it { is_expected.to eq("hello world") }
    end

    context "when the text exactly fills the limit" do
      let(:text) { "hello" }
      let(:limit) { 5 }

      it { is_expected.to eq("hello") }
    end

    context "when the text exceeds the limit" do
      let(:text) { "hello world foo bar baz" }
      let(:limit) { 12 }

      it "breaks at a word boundary and ends with an ellipsis" do
        expect(truncated).to eq("hello world…")
      end

      it "never exceeds the limit" do
        expect(truncated.length).to be <= limit
      end
    end

    context "when a single word is longer than the limit" do
      let(:text) { "supercalifragilistic" }
      let(:limit) { 10 }

      it "hard-cuts and still ends with an ellipsis within the limit" do
        expect(truncated).to end_with("…")
        expect(truncated.length).to eq(10)
      end
    end

    context "with nil" do
      let(:text) { nil }
      let(:limit) { 10 }

      it { is_expected.to eq("") }
    end
  end
end
