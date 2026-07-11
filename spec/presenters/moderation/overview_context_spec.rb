# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::OverviewContext do
  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
  let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }

  before do
    config.create_logging_setting!
    config.create_moderation_settings!
    config.create_spam_protection_settings!
    config.create_image_scanning_settings!
  end

  subject(:context) { described_class.new(config) }

  describe "#logging_ready?" do
    context "when logging plugin is enabled and channel is set" do
      before do
        config.logging_setting.update!(channel_id: 111)
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(context.logging_ready?).to be(true) }
    end

    context "when logging plugin is enabled but no channel" do
      before do
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(context.logging_ready?).to be(false) }
    end

    context "when logging plugin is not enabled" do
      it { expect(context.logging_ready?).to be(false) }
    end

    context "when logging plugin is enabled but logging_setting has no channel_id" do
      before do
        config.logging_setting.update!(channel_id: nil)
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(context.logging_ready?).to be(false) }
    end

    context "when logging plugin is enabled but logging_setting is absent" do
      before do
        config.logging_setting.destroy!
        create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(described_class.new(config.reload).logging_ready?).to be(false) }
    end
  end

  describe "#staff_role_id" do
    context "when staff_role_id is set" do
      before { config.moderation_settings.update!(staff_role_id: 555) }

      it "returns the staff role id" do
        expect(context.staff_role_id).to eq(555)
      end
    end

    context "when no staff_role_id is set" do
      it "returns nil" do
        expect(context.staff_role_id).to be_nil
      end
    end

    context "when moderation_settings does not exist" do
      before { config.moderation_settings.destroy! }

      it "returns nil" do
        expect(described_class.new(config.reload).staff_role_id).to be_nil
      end
    end
  end

  describe "#ping_staff" do
    context "when ping_staff is enabled" do
      it "returns true" do
        expect(context.ping_staff).to be(true)
      end
    end

    context "when ping_staff is disabled" do
      before { config.moderation_settings.update!(ping_staff: false) }

      it "returns false" do
        expect(context.ping_staff).to be(false)
      end
    end

    context "when moderation_settings does not exist" do
      before { config.moderation_settings.destroy! }

      it "returns nil" do
        expect(described_class.new(config.reload).ping_staff).to be_nil
      end
    end
  end

  describe "#staff_role_present?" do
    context "when staff_role_id is set" do
      before { config.moderation_settings.update!(staff_role_id: 555) }

      it { expect(context.staff_role_present?).to be(true) }
    end

    context "when no staff_role_id" do
      it { expect(context.staff_role_present?).to be(false) }
    end
  end

  describe "#group_enabled?" do
    context "when moderation plugin activation is enabled" do
      before do
        create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(context.group_enabled?).to be(true) }
    end

    context "when moderation plugin is not activated" do
      it { expect(context.group_enabled?).to be(false) }
    end
  end

  describe "#logging_channel_name" do
    context "when logging_setting is absent" do
      before { config.logging_setting.destroy! }

      it "returns nil" do
        expect(described_class.new(config.reload).logging_channel_name).to be_nil
      end
    end

    context "when logging_setting has no channel_id" do
      it "returns nil" do
        expect(context.logging_channel_name).to be_nil
      end
    end

    context "when logging_setting has a channel_id but no matching server_channel" do
      before { config.logging_setting.update!(channel_id: 777) }

      it "returns nil" do
        expect(context.logging_channel_name).to be_nil
      end
    end

    context "when logging_setting has a channel_id with a matching server_channel" do
      before do
        config.logging_setting.update!(channel_id: 888)
        create(:server_channel, server_configuration: config, discord_id: 888, name: "mod-log")
      end

      it "returns the channel name" do
        expect(context.logging_channel_name).to eq("mod-log")
      end
    end
  end

  describe "#staff_permission_warning?" do
    subject(:staff_permission_warning) { context.staff_permission_warning? }

    context "when no staff role configured" do
      it { is_expected.to be(false) }
    end

    context "when staff_role_id is set but role absent from server_roles" do
      before { config.moderation_settings.update!(staff_role_id: 999) }

      it { is_expected.to be(false) }
    end

    context "when configured role has MANAGE_MESSAGES" do
      before do
        create(:server_role, server_configuration: config, discord_id: 700, permissions: 8192)
        config.moderation_settings.update!(staff_role_id: 700)
      end

      it { is_expected.to be(false) }
    end

    context "when configured role has no relevant permissions" do
      before do
        create(:server_role, server_configuration: config, discord_id: 701, permissions: 0)
        config.moderation_settings.update!(staff_role_id: 701)
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#sub_plugin_rows" do
    it "returns two rows for spam_protection and image_scanning" do
      rows = context.sub_plugin_rows
      expect(rows.map(&:key)).to contain_exactly(:spam_protection, :image_scanning)
    end
  end
end
