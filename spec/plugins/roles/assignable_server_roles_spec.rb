# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::AssignableServerRoles do
  let(:config) { create(:server_configuration, discord_id: 900, bot_role_position: 5) }

  before do
    create(:server_role, server_configuration: config, discord_id: 900, name: "everyone", position: 0)
    create(:server_role, server_configuration: config, discord_id: 10, name: "Member", position: 2)
    create(:server_role, server_configuration: config, discord_id: 11, name: "Admin", position: 8)
    create(:server_role, server_configuration: config, discord_id: 12, name: "Booster", position: 1, managed: true)
  end

  subject(:query) { described_class.new(config) }

  describe "#candidates" do
    it "excludes the @everyone role whose discord_id matches the guild" do
      expect(query.candidates.map(&:name)).not_to include("everyone")
    end

    it "orders candidates highest position first" do
      expect(query.candidates.map(&:name)).to eq(["Admin", "Member", "Booster"])
    end
  end

  describe "#reason_for" do
    let(:managed_role) { config.server_roles.find_by(discord_id: 12) }
    let(:above_bot_role) { config.server_roles.find_by(discord_id: 11) }
    let(:plain_role) { config.server_roles.find_by(discord_id: 10) }

    it "returns :managed for a Discord-managed role" do
      expect(query.reason_for(managed_role)).to eq(:managed)
    end

    it "returns :above_bot for a role at or above bot_role_position" do
      expect(query.reason_for(above_bot_role)).to eq(:above_bot)
    end

    it "returns nil for a plain assignable role" do
      expect(query.reason_for(plain_role)).to be_nil
    end
  end

  describe "#assignable_ids" do
    it "returns only discord_ids of assignable roles" do
      expect(query.assignable_ids).to contain_exactly(10)
    end
  end

  describe "#any_unassignable?" do
    it "returns true when managed or above-bot candidates exist" do
      expect(query.any_unassignable?).to be(true)
    end

    context "when no managed or above-bot candidates exist" do
      let(:clean_config) { create(:server_configuration, discord_id: 800, bot_role_position: nil) }

      before do
        create(:server_role, server_configuration: clean_config, discord_id: 800, name: "everyone", position: 0)
        create(:server_role, server_configuration: clean_config, discord_id: 20, name: "Member", position: 2)
      end

      subject(:clean_query) { described_class.new(clean_config) }

      it "returns false" do
        expect(clean_query.any_unassignable?).to be(false)
      end
    end
  end
end
