# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_id:,
      enabled:,
      role_sets:
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

    it "assigns increasing positions across several new sets in one save" do
      described_class.call(
        server_configuration: config,
        channel_id:,
        enabled: "0",
        role_sets: [
          {name: "First", selection_mode: "multi", role_ids: []},
          {name: "Second", selection_mode: "single", role_ids: []}
        ]
      )
      expect(setting.role_sets.order(:position).pluck(:name)).to eq(["First", "Second"])
      expect(setting.role_sets.pluck(:position).uniq.size).to eq(2)
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
      expect { described_class.call(server_configuration: config, channel_id:, enabled: "0", role_sets: []) }
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

  context "with a stale or forged set id" do
    let(:role_sets) { [{id: "rst_missing", name: "Ghost", selection_mode: "multi", role_ids: []}] }

    it "skips it instead of raising RecordNotFound" do
      expect { result }.not_to raise_error
      expect(result).to be_success
      expect(setting.role_sets).to be_empty
    end

    it "won't touch a set id that belongs to another server" do
      other = create(:role_set, name: "Theirs")
      described_class.call(server_configuration: config, channel_id:, enabled: "0", role_sets: [{id: other.id, name: "Hijacked", selection_mode: "multi", role_ids: []}])
      expect(other.reload.name).to eq("Theirs")
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

  context "with ConfigBus publication" do
    before do
      allow(ConfigBus).to receive(:post_roles)
      allow(ConfigBus).to receive(:delete_roles_message)
    end

    context "when enabled with a new set" do
      let(:enabled) { "1" }
      let(:role_sets) { [{name: "Pings", selection_mode: "multi", channel_override: "", role_ids: []}] }

      it "publishes a post event for the new set" do
        result
        expect(ConfigBus).to have_received(:post_roles).with(an_instance_of(Roles::Set))
      end

      it "does not publish a delete event" do
        result
        expect(ConfigBus).not_to have_received(:delete_roles_message)
      end
    end

    context "when enabled with an existing set whose channel does not change" do
      let(:enabled) { "1" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "", role_ids: []}] }

      before { setting.update!(channel_id: 555) }

      it "publishes a post event (bot edits in place)" do
        result
        expect(ConfigBus).to have_received(:post_roles).with(existing)
      end

      it "does not delete (message_id preserved)" do
        result
        expect(ConfigBus).not_to have_received(:delete_roles_message)
        expect(existing.reload.message_id).to eq(111)
      end
    end

    context "when enabled with an existing set whose channel_override changes" do
      let(:enabled) { "1" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: 777) }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "888", role_ids: []}] }

      it "publishes a delete event for the old channel/message" do
        result
        expect(ConfigBus).to have_received(:delete_roles_message).with(channel_id: 777, message_id: 111)
      end

      it "clears message_id so bot creates fresh in the new channel" do
        result
        expect(existing.reload.message_id).to be_nil
      end

      it "publishes a post event" do
        result
        expect(ConfigBus).to have_received(:post_roles).with(existing)
      end
    end

    context "when disabled with existing sets that have message_ids" do
      let(:enabled) { "0" }
      let!(:set_a) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let!(:set_b) { create(:role_set, role_setting: setting, message_id: 222, channel_override: nil) }
      let(:role_sets) do
        [
          {id: set_a.id, name: set_a.name, selection_mode: set_a.selection_mode, channel_override: "", role_ids: []},
          {id: set_b.id, name: set_b.name, selection_mode: set_b.selection_mode, channel_override: "", role_ids: []}
        ]
      end

      before { setting.update!(channel_id: 555) }

      it "publishes delete events for all sets with messages" do
        result
        expect(ConfigBus).to have_received(:delete_roles_message).twice
      end

      it "does not publish any post events" do
        result
        expect(ConfigBus).not_to have_received(:post_roles)
      end

      it "clears message_ids" do
        result
        expect(set_a.reload.message_id).to be_nil
        expect(set_b.reload.message_id).to be_nil
      end
    end

    context "when a set is destroyed and had a message" do
      let(:enabled) { "1" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let(:role_sets) { [] }

      before { setting.update!(channel_id: 555) }

      it "publishes a delete event for the destroyed set" do
        result
        expect(ConfigBus).to have_received(:delete_roles_message).with(
          channel_id: 555,
          message_id: 111
        )
      end
    end

    context "when the default channel changes (set has no channel_override)" do
      let(:enabled) { "1" }
      let!(:old_setting) { setting.tap { |s| s.update!(channel_id: 100) } }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let(:channel_id) { "200" }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "", role_ids: []}] }

      it "publishes a delete event using the OLD default channel" do
        result
        expect(ConfigBus).to have_received(:delete_roles_message).with(channel_id: 100, message_id: 111)
      end
    end

    context "when the same channel is submitted as a String (Integer/String coercion guard)" do
      let(:enabled) { "1" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let(:channel_id) { "555" }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "", role_ids: []}] }

      before { setting.update!(channel_id: 555) }

      it "does NOT produce a delete (channel unchanged)" do
        result
        expect(ConfigBus).not_to have_received(:delete_roles_message)
      end
    end

    context "when an existing set uses a channel_override (set-level channel, not default)" do
      let(:enabled) { "1" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: 777) }
      let(:channel_id) { "555" }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "777", role_ids: []}] }

      it "does not delete (channel_override unchanged)" do
        result
        expect(ConfigBus).not_to have_received(:delete_roles_message)
        expect(existing.reload.message_id).to eq(111)
      end
    end

    context "when no channel_override and no default channel submitted (both nil)" do
      let(:enabled) { "0" }
      let(:channel_id) { "" }
      let!(:existing) { create(:role_set, role_setting: setting, message_id: 111, channel_override: nil) }
      let(:role_sets) { [{id: existing.id, name: existing.name, selection_mode: existing.selection_mode, channel_override: "", role_ids: []}] }

      it "succeeds without raising" do
        expect { result }.not_to raise_error
      end
    end

    context "on validation failure" do
      let(:role_sets) { [{name: "", selection_mode: "multi", role_ids: []}] }

      it "publishes nothing" do
        result
        expect(ConfigBus).not_to have_received(:post_roles)
        expect(ConfigBus).not_to have_received(:delete_roles_message)
      end
    end
  end
end
