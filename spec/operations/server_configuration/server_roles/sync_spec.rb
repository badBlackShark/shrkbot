require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerRoles::Sync do
  subject(:result) { described_class.call(server_configuration: server, roles:, bot_role_position: 4) }

  let(:server) { create(:server_configuration) }

  describe "upserting roles" do
    let(:roles) do
      [
        {discord_id: 111, name: "Admin", position: 3, managed: false},
        {discord_id: 222, name: "Bot", position: 2, managed: true}
      ]
    end

    it "creates a row per incoming role" do
      expect { result }.to change { server.server_roles.count }.from(0).to(2)
    end

    it "stores each role's position and managed flag" do
      result

      expect(server.server_roles.find_by(discord_id: 222)).to have_attributes(position: 2, managed: true)
    end

    it "records the bot's highest role position on the server" do
      result

      expect(server.reload.bot_role_position).to eq(4)
    end

    context "when a role was renamed or moved since the last sync" do
      before do
        create(:server_role, server_configuration: server, discord_id: 111, name: "old", position: 9)
      end

      it "updates the existing row in place rather than duplicating" do
        result

        expect(server.server_roles.find_by(discord_id: 111)).to have_attributes(name: "Admin", position: 3)
        expect(server.server_roles.where(discord_id: 111).count).to eq(1)
      end
    end
  end

  describe "pruning" do
    let(:roles) { [{discord_id: 111, name: "Admin", position: 1, managed: false}] }

    before do
      create(:server_role, server_configuration: server, discord_id: 999, name: "gone")
    end

    it "removes roles no longer present" do
      result

      expect(server.server_roles.where(discord_id: 999)).to be_empty
    end
  end
end
