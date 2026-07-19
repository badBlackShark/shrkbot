# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Lfg::Configure do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      enabled:,
      cooldown_seconds:,
      post_lifetime_minutes:,
      default_min_membership_days:,
      default_required_role_ids:,
      default_excluded_role_ids:,
      allowed_channel_ids:,
      pingable_roles:
    )
  end

  let(:config) { create(:server_configuration) }
  let!(:plugin) { create(:plugin, key: "lfg", name: "Looking for Game") }
  let!(:settings) { config.create_lfg_settings! }
  let(:enabled) { "1" }
  let(:cooldown_seconds) { 300 }
  let(:post_lifetime_minutes) { 360 }
  let(:default_min_membership_days) { nil }
  let(:default_required_role_ids) { [] }
  let(:default_excluded_role_ids) { [] }
  let(:allowed_channel_ids) { [] }
  let(:pingable_roles) { [] }

  context "happy path (enabled)" do
    let(:cooldown_seconds) { 900 }
    let(:post_lifetime_minutes) { 720 }

    it "succeeds" do
      expect(result).to be_success
    end

    it "saves the settings values" do
      result
      reloaded = settings.reload
      expect(reloaded.cooldown_seconds).to eq(900)
      expect(reloaded.post_lifetime_minutes).to eq(720)
    end

    it "enables the lfg activation" do
      result
      expect(config.plugin_activations.find_by(plugin:).enabled).to be(true)
    end
  end

  context "when saving without enabling" do
    let(:enabled) { "0" }

    it "succeeds" do
      expect(result).to be_success
    end

    it "does not enable the activation" do
      result
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end

  context "with an invalid settings value" do
    let(:cooldown_seconds) { 90_000 }
    let(:enabled) { "0" }

    it "fails" do
      expect(result).to be_failure
    end

    it "persists nothing" do
      result
      expect(config.plugin_activations.find_by(plugin:)&.enabled).to be_falsey
    end
  end

  context "with a new pingable role" do
    let(:enabled) { "0" }
    let(:pingable_roles) do
      [{role_id: "77", min_membership_days: "30", required_role_ids: [10], excluded_role_ids: [], allowed_channel_ids: nil}]
    end

    it "creates one pingable role with the given attributes" do
      result
      role = settings.pingable_roles.sole
      expect(role).to have_attributes(
        role_id: 77,
        min_membership_days: 30,
        required_role_ids: [10],
        allowed_channel_ids: nil
      )
    end
  end

  context "with an existing pingable role updated" do
    let(:enabled) { "0" }
    let!(:existing) do
      settings.pingable_roles.create!(role_id: 77, min_membership_days: 10, required_role_ids: [1], excluded_role_ids: [], allowed_channel_ids: nil)
    end
    let(:pingable_roles) do
      [{role_id: "77", min_membership_days: "60", required_role_ids: [2, 3], excluded_role_ids: [], allowed_channel_ids: [55]}]
    end

    it "updates the role in place without changing the count" do
      expect { result }.not_to change { settings.pingable_roles.count }
      expect(existing.reload).to have_attributes(
        min_membership_days: 60,
        required_role_ids: [2, 3],
        allowed_channel_ids: [55]
      )
    end
  end

  context "with a dropped pingable role" do
    let(:enabled) { "0" }
    let!(:kept_role) { settings.pingable_roles.create!(role_id: 77, excluded_role_ids: [], required_role_ids: []) }
    let!(:dropped_role) { settings.pingable_roles.create!(role_id: 88, excluded_role_ids: [], required_role_ids: []) }
    let(:pingable_roles) do
      [{role_id: "77", min_membership_days: nil, required_role_ids: [], excluded_role_ids: [], allowed_channel_ids: nil}]
    end

    it "destroys the omitted role" do
      result
      expect(Lfg::PingableRole.find_by(id: dropped_role.id)).to be_nil
      expect(Lfg::PingableRole.find_by(id: kept_role.id)).to be_present
    end
  end

  context "with _destroy truthy on an existing role" do
    let(:enabled) { "0" }
    let!(:existing) { settings.pingable_roles.create!(role_id: 77, excluded_role_ids: [], required_role_ids: []) }
    let(:pingable_roles) do
      [{role_id: "77", min_membership_days: nil, required_role_ids: [], excluded_role_ids: [], allowed_channel_ids: nil, _destroy: "1"}]
    end

    it "removes the role" do
      result
      expect(Lfg::PingableRole.find_by(id: existing.id)).to be_nil
    end
  end

  context "atomicity: an invalid pingable role rolls back settings changes too" do
    let(:enabled) { "0" }
    let(:cooldown_seconds) { 900 }
    let(:pingable_roles) do
      [{role_id: "77", min_membership_days: nil, required_role_ids: [], excluded_role_ids: [], allowed_channel_ids: []}]
    end

    it "fails" do
      expect(result).to be_failure
    end

    it "does not persist the settings changes from the same call" do
      result
      expect(settings.reload.cooldown_seconds).to eq(300)
    end
  end
end
