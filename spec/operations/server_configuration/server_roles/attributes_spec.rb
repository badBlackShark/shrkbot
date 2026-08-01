# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerRoles::Attributes do
  subject(:attributes) { described_class.call(role) }

  context "with a fully populated role" do
    let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false, color: 0x37a79e, permissions: 8192} }

    it "maps the role's fields to record attributes" do
      expect(attributes).to eq(name: "Admin", position: 3, managed: false, color: 0x37a79e, permissions: 8192)
    end
  end

  context "when color is nil" do
    let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false, color: nil, permissions: 8192} }

    it "defaults color to 0" do
      expect(attributes[:color]).to eq(0)
    end
  end

  context "when permissions is nil" do
    let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false, color: 0x37a79e, permissions: nil} }

    it "defaults permissions to 0" do
      expect(attributes[:permissions]).to eq(0)
    end
  end

  context "when the role hash has no :color or :permissions keys" do
    let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false} }

    it "defaults both to 0" do
      expect(attributes).to include(color: 0, permissions: 0)
    end
  end
end
