# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::SetGlobalScam do
  subject(:result) do
    described_class.call(
      phash_hex:,
      global:
    )
  end

  let(:phash_hex) { "00000000000000ab" }
  let(:global) { true }

  it "invalidates the phash index" do
    expect(Moderation::ImageScanning::PhashIndex).to receive(:invalidate)
    result
  end

  context "when marking as global scam" do
    it "creates the phash when absent and sets global_scam true" do
      expect { result }.to change(Moderation::Phash, :count).by(1)
      expect(result).to be_success
      expect(result.value.global_scam).to be(true)
    end
  end

  context "when unmarking a global scam" do
    let(:global) { false }

    before do
      create(:phash, phash: phash_hex, global_scam: true)
    end

    it "sets global_scam false without adding a row" do
      expect { result }.not_to change(Moderation::Phash, :count)
      expect(result.value.global_scam).to be(false)
    end
  end
end
