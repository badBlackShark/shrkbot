require "rails_helper"

RSpec.describe ServerRole do
  describe "primary key" do
    subject(:id) { create(:server_role).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Asrl_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "discord_id uniqueness" do
    subject(:duplicate) { build(:server_role, server_configuration: server, discord_id: 555) }

    let(:server) { create(:server_configuration) }

    before do
      create(:server_role, server_configuration: server, discord_id: 555)
    end

    it "forbids the same discord_id twice within one server" do
      expect(duplicate).not_to be_valid
    end

    it "allows the same discord_id on a different server" do
      expect(build(:server_role, discord_id: 555)).to be_valid
    end
  end
end
