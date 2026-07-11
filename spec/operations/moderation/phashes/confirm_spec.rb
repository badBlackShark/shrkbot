# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::Confirm do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      phash_hex:
    )
  end

  let(:config) { create(:server_configuration) }
  let(:phash_hex) { "00000000000000ab" }

  it "invalidates the phash index" do
    expect(Moderation::ImageScanning::PhashIndex).to receive(:invalidate)
    result
  end

  it "creates the phash and a confirmation with the confirmed verdict" do
    expect { result }.to change(Moderation::Phash, :count).by(1)
      .and change(Moderation::PhashConfirmation, :count).by(1)
    expect(result).to be_success
    expect(result.value.verdict).to eq("confirmed")
  end

  context "when confirming the same phash and guild again" do
    before { described_class.call(server_configuration: config, phash_hex:) }

    it "upserts a single confirmation row" do
      expect { result }.not_to change(Moderation::PhashConfirmation, :count)
    end
  end

  context "when the guild previously dismissed the phash" do
    before { Ops::Moderation::Phashes::Dismiss.call(server_configuration: config, phash_hex:) }

    it "flips the verdict to confirmed without adding a row" do
      expect { result }.not_to change(Moderation::PhashConfirmation, :count)
      expect(result.value.reload.verdict).to eq("confirmed")
    end
  end
end
