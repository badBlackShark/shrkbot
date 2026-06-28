# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_id: channel_id,
      enabled: enabled,
      role_sets: role_sets
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:setting) { create(:role_setting, server_configuration: config, channel_id: nil) }
  let!(:plugin) { create(:plugin, key: "roles", name: "Roles") }
  let(:channel_id) { 555 }
  let(:enabled) { "0" }
  let(:role_sets) { [] }

  before do
    create(:server_role, server_configuration: config, discord_id: 10, position: 1)
    create(:server_role, server_configuration: config, discord_id: 11, position: 2)
  end

  it "stores the default channel" do
    result
    expect(setting.reload.channel_id).to eq(555)
  end

  context "with a new role set" do
    let(:role_sets) do
      [{name: "Pings", selection_mode: "multi", channel_override: "", role_ids: ["10", "11"]}]
    end

    it "creates the set with its assignable roles" do
      expect { result }.to change { setting.role_sets.count }.by(1)
      set = setting.role_sets.last
      expect(set).to have_attributes(name: "Pings", selection_mode: "multi", channel_override: nil)
      expect(set.assignable_roles.map(&:role_id)).to contain_exactly(10, 11)
    end

    it "drops role ids that don't belong to the server" do
      role_sets.first[:role_ids] = ["10", "999"]
      result
      expect(setting.role_sets.last.assignable_roles.map(&:role_id)).to contain_exactly(10)
    end
  end

  context "with an existing set" do
    let!(:existing) { create(:role_set, role_setting: setting, name: "Old", selection_mode: "single") }

    before { create(:assignable_role, role_set: existing, role_id: 10) }

    let(:role_sets) do
      [{id: existing.id, name: "New", selection_mode: "multi", channel_override: "777", role_ids: ["11"]}]
    end

    it "updates the set and reconciles its roles" do
      result
      expect(existing.reload).to have_attributes(name: "New", selection_mode: "multi", channel_override: 777)
      expect(existing.assignable_roles.map(&:role_id)).to contain_exactly(11)
    end

    it "deletes a set marked for destruction" do
      role_sets.first[:_destroy] = "1"
      expect { result }.to change { setting.role_sets.count }.by(-1)
    end

    it "deletes a set that is no longer submitted" do
      expect { described_class.call(server_configuration: config, channel_id: channel_id, enabled: "0", role_sets: []) }
        .to change { setting.role_sets.count }.by(-1)
    end
  end

  context "with an invalid set" do
    let(:role_sets) { [{name: "", selection_mode: "multi", role_ids: []}] }

    it "fails and persists nothing" do
      expect { result }.not_to change { setting.role_sets.count }
      expect(result).to be_failure
      expect(result.errors).to be_present
    end
  end

  context "when enabling" do
    let(:enabled) { "1" }

    it "enables the plugin once a default channel is set" do
      result
      expect(config.plugins.enabled.exists?(key: :roles)).to be(true)
    end

    context "without a default channel" do
      let(:channel_id) { "" }

      it "fails and enables nothing" do
        expect(result).to be_failure
        expect(config.plugins.enabled.exists?(key: :roles)).to be(false)
      end
    end
  end
end
