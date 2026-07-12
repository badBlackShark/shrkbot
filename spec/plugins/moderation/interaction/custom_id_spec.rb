# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Interaction::CustomId do
  let(:phash_hex) { "0123456789abcdef" }

  it "builds a confirm id" do
    expect(described_class.confirm(phash_hex)).to eq("mod:confirm:0123456789abcdef")
  end

  it "builds a dismiss id" do
    expect(described_class.dismiss(phash_hex)).to eq("mod:dismiss:0123456789abcdef")
  end

  it "builds an undo_verdict id" do
    expect(described_class.undo_verdict(phash_hex)).to eq("mod:undo_verdict:0123456789abcdef")
  end

  it "round-trips a confirm id" do
    expect(described_class.parse(described_class.confirm(phash_hex)))
      .to eq(action: :confirm, phash_hex:)
  end

  it "round-trips a dismiss id" do
    expect(described_class.parse(described_class.dismiss(phash_hex)))
      .to eq(action: :dismiss, phash_hex:)
  end

  it "round-trips an undo_verdict id" do
    expect(described_class.parse(described_class.undo_verdict(phash_hex)))
      .to eq(action: :undo_verdict, phash_hex:)
  end

  it "yields a nil action for an id with no action segment" do
    expect(described_class.parse("mod")).to eq(action: nil, phash_hex: nil)
  end
end
