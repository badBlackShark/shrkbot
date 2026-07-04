# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Metadata::Sync do
  subject(:result) do
    described_class.call(
      server_configuration: server,
      name: "Dev Refuge",
      icon_hash: "abc123",
      member_count: 42
    )
  end

  let(:server) { create(:server_configuration) }

  it "returns a successful result" do
    expect(result).to be_success
  end

  it "returns the updated server configuration" do
    expect(result.value).to eq(server)
  end

  it "writes the name to the record" do
    result
    expect(server.reload.name).to eq("Dev Refuge")
  end

  it "writes the icon_hash to the record" do
    result
    expect(server.reload.icon_hash).to eq("abc123")
  end

  it "writes the member_count to the record" do
    result
    expect(server.reload.member_count).to eq(42)
  end

  context "when icon_hash is nil" do
    subject(:result) do
      described_class.call(
        server_configuration: server,
        name: "Dev Refuge",
        icon_hash: nil,
        member_count: 42
      )
    end

    it "returns a successful result" do
      expect(result).to be_success
    end

    it "stores nil for icon_hash" do
      result
      expect(server.reload.icon_hash).to be_nil
    end
  end
end
