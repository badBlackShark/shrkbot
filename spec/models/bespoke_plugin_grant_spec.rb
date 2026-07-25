# frozen_string_literal: true

require "rails_helper"

RSpec.describe BespokePluginGrant do
  describe "validations" do
    let(:server_configuration) { create(:server_configuration) }

    it "requires a plugin_key" do
      grant = build(:bespoke_plugin_grant, server_configuration:, plugin_key: nil)

      expect(grant).not_to be_valid
      expect(grant.errors[:plugin_key]).to be_present
    end

    it "requires plugin_key to be unique within a server_configuration" do
      create(:bespoke_plugin_grant, server_configuration:, plugin_key: "lfg")
      duplicate = build(:bespoke_plugin_grant, server_configuration:, plugin_key: "lfg")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plugin_key]).to be_present
    end

    it "allows the same plugin_key across different server_configurations" do
      create(:bespoke_plugin_grant, server_configuration:, plugin_key: "lfg")
      other = build(:bespoke_plugin_grant, server_configuration: create(:server_configuration), plugin_key: "lfg")

      expect(other).to be_valid
    end
  end

  describe ".granted_keys" do
    subject(:granted_keys) { described_class.granted_keys(server_configuration) }

    let(:server_configuration) { create(:server_configuration) }
    let(:other_server_configuration) { create(:server_configuration) }

    before do
      create(:bespoke_plugin_grant, server_configuration:, plugin_key: "lfg")
      create(:bespoke_plugin_grant, server_configuration:, plugin_key: "spam_protection")
      create(:bespoke_plugin_grant, server_configuration: other_server_configuration, plugin_key: "moderation")
    end

    it "returns a Set of symbols for that server_configuration only" do
      expect(granted_keys).to eq(Set[:lfg, :spam_protection])
    end
  end
end
