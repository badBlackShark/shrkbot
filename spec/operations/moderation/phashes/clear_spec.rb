# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::Clear do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      phash_hex:
    )
  end

  let(:config) { create(:server_configuration) }
  let(:phash_hex) { "00000000000000ef" }

  before { allow(Moderation::ImageScanning::PhashIndex).to receive(:invalidate) }

  it "invalidates the phash index" do
    result
    expect(Moderation::ImageScanning::PhashIndex).to have_received(:invalidate)
  end

  it "succeeds even when no phash or confirmation exists" do
    expect { result }.not_to raise_error
    expect(result).to be_success
  end

  context "when a confirmation exists for this guild and phash" do
    before { Ops::Moderation::Phashes::Confirm.call(server_configuration: config, phash_hex:) }

    it "destroys the confirmation" do
      expect { result }.to change(Moderation::PhashConfirmation, :count).by(-1)
    end

    it "succeeds" do
      expect(result).to be_success
    end
  end

  context "when a confirmation exists for a different guild" do
    let(:other_config) { create(:server_configuration) }

    before { Ops::Moderation::Phashes::Confirm.call(server_configuration: other_config, phash_hex:) }

    it "does not destroy the other guild's confirmation" do
      expect { result }.not_to change(Moderation::PhashConfirmation, :count)
    end
  end
end
