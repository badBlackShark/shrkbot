require "rails_helper"

RSpec.describe RoleSync do
  subject(:handle) { described_class.new(event).handle }

  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:) }
  let(:op) { Ops::ServerConfiguration::ServerRoles::Sync }

  before do
    allow(GuildMetadata).to receive(:roles).with(server).and_return([:role_data])
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "re-syncs the server's roles" do
      expect(op).to receive(:call).with(server_configuration: config, roles: [:role_data])
      handle
    end
  end

  context "for an uncached server (no server)" do
    let(:server) { nil }

    it "does nothing" do
      expect(op).not_to receive(:call)
      handle
    end
  end

  context "for a server with no configuration" do
    it "does nothing" do
      expect(op).not_to receive(:call)
      handle
    end
  end
end
