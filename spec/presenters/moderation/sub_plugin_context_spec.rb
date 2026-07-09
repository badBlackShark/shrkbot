# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SubPluginContext do
  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }

  before do
    config.create_moderation_settings!
    config.create_spam_protection_settings!
    config.create_image_scanning_settings!
  end

  describe "#staff_role_present?" do
    context "when staff_role_id is set" do
      before { config.moderation_settings.update!(staff_role_id: 555) }

      subject(:ctx) { described_class.new(config, :spam_protection) }

      it { expect(ctx.staff_role_present?).to be(true) }
    end

    context "when no staff_role_id" do
      subject(:ctx) { described_class.new(config, :spam_protection) }

      it { expect(ctx.staff_role_present?).to be(false) }
    end

    context "when moderation_settings does not exist" do
      before { config.moderation_settings.destroy! }

      subject(:ctx) { described_class.new(config.reload, :spam_protection) }

      it { expect(ctx.staff_role_present?).to be(false) }
    end
  end

  describe "#settings" do
    context "when plugin_key is :spam_protection" do
      subject(:ctx) { described_class.new(config, :spam_protection) }

      it "returns the spam_protection_settings" do
        expect(ctx.settings).to eq(config.spam_protection_settings)
      end
    end

    context "when plugin_key is :image_scanning" do
      subject(:ctx) { described_class.new(config, :image_scanning) }

      it "returns the image_scanning_settings" do
        expect(ctx.settings).to eq(config.image_scanning_settings)
      end
    end
  end

  describe "#group_enabled?" do
    subject(:ctx) { described_class.new(config, :spam_protection) }

    context "when moderation plugin activation is enabled" do
      before do
        create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(ctx.group_enabled?).to be(true) }
    end

    context "when moderation plugin is not activated" do
      it { expect(ctx.group_enabled?).to be(false) }
    end
  end

  describe "#plugin_enabled?" do
    let!(:spam_plugin) { create(:plugin, key: "spam_protection", name: "Cross-Channel Spam Guard") }

    subject(:ctx) { described_class.new(config, :spam_protection) }

    context "when the plugin activation is enabled" do
      before do
        create(:plugin_activation, server_configuration: config, plugin: spam_plugin, enabled: false)
          .update_column(:enabled, true)
      end

      it { expect(ctx.plugin_enabled?).to be(true) }
    end

    context "when the plugin has no activation" do
      it { expect(ctx.plugin_enabled?).to be(false) }
    end
  end
end
