# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginCatalog do
  describe ".all" do
    it "returns every definition" do
      expect(described_class.all).to eq(PluginCatalog::DEFINITIONS)
    end
  end

  describe ".find" do
    it "looks a definition up by key" do
      expect(described_class.find(:logging).name).to eq("Logging")
    end

    it "is nil for an unknown key" do
      expect(described_class.find(:nope)).to be_nil
    end
  end

  describe ".channel_backed" do
    it "returns only the channel-backed definitions" do
      expect(described_class.channel_backed).to all(be_channel_backed)
    end
  end

  describe ".sub_plugin?" do
    it "returns true for :spam_protection" do
      expect(described_class.sub_plugin?(:spam_protection)).to be(true)
    end

    it "returns true for :image_scanning" do
      expect(described_class.sub_plugin?(:image_scanning)).to be(true)
    end

    it "returns false for :moderation" do
      expect(described_class.sub_plugin?(:moderation)).to be(false)
    end

    it "returns false for :roles" do
      expect(described_class.sub_plugin?(:roles)).to be(false)
    end
  end

  describe ".sub_plugin_keys" do
    it "returns [:spam_protection, :image_scanning] for :moderation" do
      expect(described_class.sub_plugin_keys(:moderation)).to eq([:spam_protection, :image_scanning])
    end
  end

  describe "moderation group wiring" do
    it "spam_protection has parent :moderation" do
      expect(described_class.find(:spam_protection).parent).to eq(:moderation)
    end

    it "image_scanning has parent :moderation" do
      expect(described_class.find(:image_scanning).parent).to eq(:moderation)
    end

    it "moderation requires_plugin :logging" do
      expect(described_class.find(:moderation).requires_plugin).to eq(:logging)
    end
  end

  describe PluginCatalog::Definition do
    def definition(channel_setting:)
      described_class.new(key: :x, name: "X", description: "", channel_setting:)
    end

    context "when not channel-backed" do
      it "has no prerequisites" do
        expect(definition(channel_setting: nil).prerequisites_met?(Object.new)).to be(true)
      end
    end

    context "when channel-backed" do
      subject(:check) { definition(channel_setting: :logging_setting).prerequisites_met?(config) }

      context "without a channel" do
        let(:config) { double(logging_setting: nil) }

        it { is_expected.to be(false) }
      end

      context "with a channel" do
        let(:config) { double(logging_setting: double(channel_id: 5)) }

        it { is_expected.to be(true) }
      end
    end

    context "when requiring another plugin (requires_plugin: :logging)" do
      def requiring_definition
        described_class.new(key: :x, name: "X", description: "", requires_plugin: :logging)
      end

      subject(:check) { requiring_definition.prerequisites_met?(config) }

      context "when required plugin is not enabled" do
        let(:config) { double(enabled_plugin_keys: Set[]) }

        it { is_expected.to be(false) }
      end

      context "when required plugin is enabled" do
        let(:config) { double(enabled_plugin_keys: Set[:logging]) }

        it { is_expected.to be(true) }
      end
    end

    context "when a group member (parent: :moderation)" do
      def child_definition
        described_class.new(key: :x, name: "X", description: "", parent: :moderation)
      end

      subject(:check) { child_definition.prerequisites_met?(config) }

      context "when parent plugin is not enabled" do
        let(:config) { double(enabled_plugin_keys: Set[]) }

        it { is_expected.to be(false) }
      end

      context "when parent plugin is enabled" do
        let(:config) { double(enabled_plugin_keys: Set[:moderation]) }

        it { is_expected.to be(true) }
      end
    end

    context "when a prerequisite predicate is set" do
      def definition_with_predicate(predicate)
        described_class.new(key: :x, name: "X", description: "", prerequisite: predicate)
      end

      subject(:check) { definition_with_predicate(predicate).prerequisites_met?(config) }

      context "when predicate returns false" do
        let(:predicate) { ->(_c) { false } }
        let(:config) { double }

        it { is_expected.to be(false) }
      end

      context "when predicate returns true" do
        let(:predicate) { ->(_c) { true } }
        let(:config) { double }

        it { is_expected.to be(true) }
      end
    end
  end

  describe "moderation prerequisite lambdas with real ServerConfiguration" do
    let(:config) { create(:server_configuration, discord_id: 900_000_001) }
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }
    let!(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }

    before do
      config.create_logging_setting!
      config.create_moderation_settings!
      config.create_spam_protection_settings!
      config.create_image_scanning_settings!
    end

    describe ":moderation prerequisite lambda" do
      subject(:check) { PluginCatalog.find(:moderation).prerequisites_met?(config) }

      context "when logging is enabled and channel is set" do
        before do
          config.logging_setting.update!(channel_id: 111)
          create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        it { is_expected.to be(true) }
      end

      context "when logging is enabled but no channel is set" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        it { is_expected.to be(false) }
      end

      context "when logging is enabled but logging_setting is absent" do
        before do
          config.logging_setting.destroy!
          create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        subject(:check) { PluginCatalog.find(:moderation).prerequisites_met?(config.reload) }

        it { is_expected.to be(false) }
      end
    end

    describe ":spam_protection prerequisite lambda" do
      subject(:check) { PluginCatalog.find(:spam_protection).prerequisites_met?(config) }

      context "when moderation is enabled and staff_role_id is set" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
          config.moderation_settings.update!(staff_role_id: 500)
        end

        it { is_expected.to be(true) }
      end

      context "when moderation is enabled but no staff_role_id" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        it { is_expected.to be(false) }
      end

      context "when moderation is enabled but moderation_settings is absent" do
        before do
          config.moderation_settings.destroy!
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        subject(:check) { PluginCatalog.find(:spam_protection).prerequisites_met?(config.reload) }

        it { is_expected.to be(false) }
      end
    end

    describe ":image_scanning prerequisite lambda" do
      subject(:check) { PluginCatalog.find(:image_scanning).prerequisites_met?(config) }

      context "when moderation is enabled and staff_role_id is set" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
          config.moderation_settings.update!(staff_role_id: 501)
        end

        it { is_expected.to be(true) }
      end

      context "when moderation is enabled but no staff_role_id" do
        before do
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        it { is_expected.to be(false) }
      end

      context "when moderation is enabled but moderation_settings is absent" do
        before do
          config.moderation_settings.destroy!
          create(:plugin_activation, server_configuration: config, plugin: moderation_plugin, enabled: false)
            .update_column(:enabled, true)
        end

        subject(:check) { PluginCatalog.find(:image_scanning).prerequisites_met?(config.reload) }

        it { is_expected.to be(false) }
      end
    end
  end

  describe "moderation prerequisite predicates" do
    let(:enabled_keys) { Set[:logging, :moderation] }

    describe ":moderation prerequisite" do
      subject(:check) { PluginCatalog.find(:moderation).prerequisites_met?(config) }

      context "when logging enabled but no logging channel" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            logging_setting: double(channel_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when logging enabled with a logging channel" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            logging_setting: double(channel_id: 999)
          )
        end

        it { is_expected.to be(true) }
      end
    end

    describe ":spam_protection prerequisite" do
      subject(:check) { PluginCatalog.find(:spam_protection).prerequisites_met?(config) }

      context "when group enabled but no staff role" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            moderation_settings: double(staff_role_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when group enabled with staff role" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            moderation_settings: double(staff_role_id: 123)
          )
        end

        it { is_expected.to be(true) }
      end
    end

    describe ":image_scanning prerequisite" do
      subject(:check) { PluginCatalog.find(:image_scanning).prerequisites_met?(config) }

      context "when group enabled but no staff role" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            moderation_settings: double(staff_role_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when group enabled with staff role" do
        let(:config) do
          double(
            enabled_plugin_keys: enabled_keys,
            moderation_settings: double(staff_role_id: 456)
          )
        end

        it { is_expected.to be(true) }
      end
    end
  end
end
