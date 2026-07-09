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
        let(:config) { double(plugins: double(enabled: double(exists?: false))) }

        it { is_expected.to be(false) }
      end

      context "when required plugin is enabled" do
        let(:enabled_scope) do
          scope = double
          allow(scope).to receive(:exists?).with(key: :logging).and_return(true)
          scope
        end
        let(:config) { double(plugins: double(enabled: enabled_scope)) }

        it { is_expected.to be(true) }
      end
    end

    context "when a group member (parent: :moderation)" do
      def child_definition
        described_class.new(key: :x, name: "X", description: "", parent: :moderation)
      end

      subject(:check) { child_definition.prerequisites_met?(config) }

      context "when parent plugin is not enabled" do
        let(:config) { double(plugins: double(enabled: double(exists?: false))) }

        it { is_expected.to be(false) }
      end

      context "when parent plugin is enabled" do
        let(:enabled_scope) do
          scope = double
          allow(scope).to receive(:exists?).with(key: :moderation).and_return(true)
          scope
        end
        let(:config) { double(plugins: double(enabled: enabled_scope)) }

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

  describe "moderation prerequisite predicates" do
    let(:enabled_scope) { double }

    before do
      allow(enabled_scope).to receive(:exists?).and_return(true)
    end

    describe ":moderation prerequisite" do
      subject(:check) { PluginCatalog.find(:moderation).prerequisites_met?(config) }

      context "when logging enabled but no logging channel" do
        let(:config) do
          double(
            plugins: double(enabled: enabled_scope),
            logging_setting: double(channel_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when logging enabled with a logging channel" do
        let(:config) do
          double(
            plugins: double(enabled: enabled_scope),
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
            plugins: double(enabled: enabled_scope),
            moderation_settings: double(staff_role_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when group enabled with staff role" do
        let(:config) do
          double(
            plugins: double(enabled: enabled_scope),
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
            plugins: double(enabled: enabled_scope),
            moderation_settings: double(staff_role_id: nil)
          )
        end

        it { is_expected.to be(false) }
      end

      context "when group enabled with staff role" do
        let(:config) do
          double(
            plugins: double(enabled: enabled_scope),
            moderation_settings: double(staff_role_id: 456)
          )
        end

        it { is_expected.to be(true) }
      end
    end
  end
end
