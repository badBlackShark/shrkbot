# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Canonicalizer do
  subject(:result) { described_class.call(text, **options) }

  let(:options) { {} }

  context "NFKC folding" do
    let(:text) { "Ｈello" }

    it "folds fullwidth characters to ASCII equivalents and downcases" do
      expect(result).to eq("hello")
    end
  end

  context "zero-width character removal" do
    let(:text) { "he​llo" }

    it "strips zero-width spaces" do
      expect(result).to eq("hello")
    end
  end

  context "downcasing" do
    let(:text) { "HELLO World" }

    it "lowercases all characters" do
      expect(result).to eq("hello world")
    end
  end

  context "punctuation replacement" do
    let(:text) { "hello, world! foo.bar" }

    it "replaces punctuation with spaces and collapses runs" do
      expect(result).to eq("hello world foo bar")
    end
  end

  context "with strip_digits: true" do
    let(:text) { "abc123def" }
    let(:options) { {strip_digits: true} }

    it "removes digits" do
      expect(result).to eq("abc def")
    end
  end

  context "with default strip_digits (false)" do
    let(:text) { "abc123def" }

    it "keeps digits" do
      expect(result).to eq("abc123def")
    end
  end

  context "leading and trailing whitespace" do
    let(:text) { "  hello world  " }

    it "strips surrounding whitespace" do
      expect(result).to eq("hello world")
    end
  end
end
