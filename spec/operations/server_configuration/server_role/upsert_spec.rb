# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerRole::Upsert do
  subject(:result) { described_class.call(server_configuration: server, role:) }

  let(:server) { create(:server_configuration) }
  let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false, color: 0x37a79e, permissions: 8192} }

  context "for an unseen discord_id" do
    it "creates a row" do
      expect { result }.to change { server.server_roles.count }.from(0).to(1)
    end

    it "stores the role's attributes" do
      result

      expect(server.server_roles.find_by(discord_id: 111)).to have_attributes(
        name: "Admin", position: 3, managed: false, color: 0x37a79e, permissions: 8192
      )
    end

    context "when color and permissions are missing" do
      let(:role) { {discord_id: 111, name: "Admin", position: 3, managed: false} }

      it "defaults them to 0" do
        result

        expect(server.server_roles.find_by(discord_id: 111)).to have_attributes(color: 0, permissions: 0)
      end
    end
  end

  context "for a known discord_id" do
    let!(:existing) { create(:server_role, server_configuration: server, discord_id: 111, name: "old", position: 9) }

    it "updates the existing row rather than creating a second" do
      expect { result }.not_to change { server.server_roles.count }
    end

    it "writes the new attributes onto the existing row" do
      result

      expect(existing.reload).to have_attributes(name: "Admin", position: 3)
    end
  end
end
