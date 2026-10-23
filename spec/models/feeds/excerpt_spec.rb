# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Excerpt do
  subject(:excerpt) { described_class.new(text, limit).to_s }

  let(:limit) { 20 }

  it "knows the two body lengths a subscription can choose" do
    expect(described_class::LIMITS).to eq("preview" => 500, "full" => 3500)
  end

  context "when the text is within the limit" do
    let(:text) { "Short text\n\nfine." }

    it "is unchanged" do
      expect(excerpt).to eq(text)
    end
  end

  context "when the text is nil" do
    let(:text) { nil }

    it "is empty" do
      expect(excerpt).to eq("")
    end
  end

  context "when a paragraph break sits past the half of the limit" do
    let(:text) { "Aaaa bbbb cccc\n\ndddd eeee ffff" }

    it "cuts at the paragraph break" do
      expect(excerpt).to eq("Aaaa bbbb cccc…")
    end
  end

  context "when the last paragraph break would leave less than half the limit" do
    let(:text) { "Aa\n\nbbbb cccc dddd\neeee ffff gggg" }

    it "cuts at the last line break instead" do
      expect(excerpt).to eq("Aa\n\nbbbb cccc dddd…")
    end
  end

  context "when no break leaves at least half the limit" do
    let(:text) { "A\nBBBBB CCCCC DDDDDDDDDD" }

    it "cuts at the last space" do
      expect(excerpt).to eq("A\nBBBBB CCCCC…")
    end
  end

  context "when the text has no break at all" do
    let(:text) { "A" * 40 }

    it "cuts hard at the limit" do
      expect(excerpt).to eq("#{"A" * 20}…")
    end
  end

  context "when the cut leaves a code fence open" do
    let(:text) { "```\nline one\nline two\nline three" }
    let(:limit) { 25 }

    it "closes the fence before the ellipsis" do
      expect(excerpt).to eq("```\nline one\nline two\n```\n…")
    end
  end

  context "when the kept text has balanced fences" do
    let(:text) { "```\nx\n```\n\nafter the fence, plenty more" }
    let(:limit) { 25 }

    it "adds no extra fence" do
      expect(excerpt).to eq("```\nx\n```\n\nafter the…")
    end
  end
end
