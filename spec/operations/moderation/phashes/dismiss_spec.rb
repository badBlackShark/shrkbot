# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Phashes::Dismiss do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      phash_hex:
    )
  end

  let(:config) { create(:server_configuration) }
  let(:phash_hex) { "00000000000000cd" }

  it "invalidates the phash index" do
    expect(Moderation::ImageScanning::PhashIndex).to receive(:invalidate)
    result
  end

  it "creates the phash and a confirmation with the dismissed verdict" do
    expect { result }.to change(Moderation::Phash, :count).by(1)
      .and change(Moderation::PhashConfirmation, :count).by(1)
    expect(result).to be_success
    expect(result.value.verdict).to eq("dismissed")
  end
end
