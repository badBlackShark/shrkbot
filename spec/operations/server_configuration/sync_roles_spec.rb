require "rails_helper"

RSpec.describe Ops::ServerConfiguration::SyncRoles do
  subject(:result) { described_class.call(server_configuration: server, roles:) }

  let(:server) { create(:server_configuration) }

  describe "upserting roles" do
    let(:roles) { [{discord_id: 111, name: "Admin"}, {discord_id: 222, name: "Member"}] }

    it "creates a row per incoming role" do
      expect { result }.to change { server.server_roles.count }.from(0).to(2)
    end

    context "when a role was renamed since the last sync" do
      before do
        create(:server_role, server_configuration: server, discord_id: 111, name: "old")
      end

      it "updates the existing row in place rather than duplicating" do
        result

        expect(server.server_roles.find_by(discord_id: 111).name).to eq("Admin")
        expect(server.server_roles.where(discord_id: 111).count).to eq(1)
      end
    end
  end

  describe "pruning" do
    let(:roles) { [{discord_id: 111, name: "Admin"}] }

    before do
      create(:server_role, server_configuration: server, discord_id: 999, name: "gone")
    end

    it "removes roles no longer present" do
      result

      expect(server.server_roles.where(discord_id: 999)).to be_empty
    end
  end
end
