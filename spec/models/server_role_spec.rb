# frozen_string_literal: true

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

  describe "#manage_messages?" do
    subject(:result) { role.manage_messages? }

    context "when role has MANAGE_MESSAGES bit" do
      let(:role) { build(:server_role, permissions: ServerRole::MANAGE_MESSAGES) }

      it { is_expected.to be(true) }
    end

    context "when role has ADMINISTRATOR bit only" do
      let(:role) { build(:server_role, permissions: ServerRole::ADMINISTRATOR) }

      it { is_expected.to be(true) }
    end

    context "when role has an unrelated bit (VIEW_CHANNEL = 1 << 10)" do
      let(:role) { build(:server_role, permissions: 1 << 10) }

      it { is_expected.to be(false) }
    end

    context "when role has no permissions" do
      let(:role) { build(:server_role, permissions: 0) }

      it { is_expected.to be(false) }
    end
  end
end
