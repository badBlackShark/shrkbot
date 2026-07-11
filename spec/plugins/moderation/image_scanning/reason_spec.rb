# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::Reason do
  subject(:reason) { described_class.new(key: :rule, weight: 3) }

  it "defaults detail to nil" do
    expect(reason.detail).to be_nil
  end

  it "accepts an explicit detail" do
    r = described_class.new(key: :rule, weight: 3, detail: "promo code")
    expect(r.detail).to eq("promo code")
  end
end
