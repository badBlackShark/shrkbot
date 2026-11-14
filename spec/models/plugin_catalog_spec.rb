# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginCatalog do
  describe ".all" do
    it "returns every definition" do
      expect(described_class.all).to eq(PluginCatalog::DEFINITIONS)
    end

    it "has a sidebar name and description translation for every top-level plugin" do
      top_level = described_class.all.reject { |definition| described_class.sub_plugin?(definition.key) }
      top_level.each do |definition|
        expect(I18n.exists?("components.plugin_row.plugin.#{definition.key}.name", :en)).to be(true)
        expect(I18n.exists?("components.plugin_row.plugin.#{definition.key}.description", :en)).to be(true)
      end
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

  describe "badges" do
    include ActiveSupport::Testing::TimeHelpers

    let(:added_on) { Date.new(2026, 11, 1) }
    let(:today) { added_on }
    let(:definition) { described_class::Definition.new(key: :x, name: "X", description: "x", added_on:, beta: true) }

    around do |example|
      travel_to(today) { example.run }
    end

    describe "Definition#recently_added?" do
      subject(:recently_added) { definition.recently_added? }

      it "is true on the day it was added" do
        expect(recently_added).to be(true)
      end

      context "on the last day of the window" do
        let(:today) { added_on + 29.days }

        it "is true" do
          expect(recently_added).to be(true)
        end
      end

      context "once the window has passed" do
        let(:today) { added_on + 30.days }

        it "is false" do
          expect(recently_added).to be(false)
        end
      end

      context "without an added_on date" do
        let(:added_on) { nil }
        let(:today) { Date.new(2026, 11, 1) }

        it "is false" do
          expect(recently_added).to be(false)
        end
      end
    end

    describe ".recently_added? and .beta?" do
      before do
        allow(described_class).to receive(:find).and_call_original
        allow(described_class).to receive(:find).with(:x).and_return(definition)
      end

      it "are false for a global plugin, which has no catalog entry" do
        expect(described_class.recently_added?(:reminders)).to be(false)
        expect(described_class.beta?(:reminders)).to be(false)
      end

      it "read the flags off the definition" do
        expect(described_class.recently_added?(:x)).to be(true)
        expect(described_class.beta?(:x)).to be(true)
      end

      context "with a new beta sub-plugin" do
        before do
          allow(described_class).to receive(:find).with(:steam).and_return(definition)
        end

        it "marks its parent new, but not beta" do
          expect(described_class.recently_added?(:integrations)).to be(true)
          expect(described_class.beta?(:integrations)).to be(false)
        end
      end
    end
  end

  describe ".channel_backed" do
    it "returns only the channel-backed definitions" do
      expect(described_class.channel_backed).to all(be_channel_backed)
    end
  end

  describe ".bespoke" do
    include_context "with a bespoke plugin definition"

    it "selects only bespoke definitions" do
      expect(described_class.bespoke).to all(have_attributes(bespoke: true))
    end

    it "includes a stubbed-in bespoke definition" do
      expect(described_class.bespoke).to include(bespoke_definition)
    end
  end

  describe ".visible_for" do
    include_context "with a bespoke plugin definition"

    let(:config) { create(:server_configuration) }

    it "hides an ungranted bespoke definition" do
      expect(described_class.visible_for(config)).not_to include(bespoke_definition)
    end

    it "includes a granted bespoke definition" do
      create(:bespoke_plugin_grant, server_configuration: config, plugin_key: bespoke_definition.key)

      expect(described_class.visible_for(config)).to include(bespoke_definition)
    end

    it "always includes non-bespoke definitions" do
      expect(described_class.visible_for(config)).to include(described_class.find(:logging))
    end
  end

  describe "bespoke definitions and prerequisites_met?" do
    subject(:check) { bespoke_definition.prerequisites_met?(config) }

    include_context "with a bespoke plugin definition"

    let(:config) { create(:server_configuration) }

    context "when ungranted" do
      it { is_expected.to be(false) }
    end

    context "when granted" do
      before { create(:bespoke_plugin_grant, server_configuration: config, plugin_key: bespoke_definition.key) }

      it { is_expected.to be(true) }
    end
  end

  describe ".dependents_of" do
    it "lists the plugins that require the logging plugin" do
      expect(described_class.dependents_of(:logging).map(&:key)).to eq([:spam_protection, :image_scanning])
    end

    it "lists a group's members" do
      expect(described_class.dependents_of(:moderation).map(&:key)).to eq([:spam_protection, :image_scanning])
    end
  end

  describe ".group" do
    it "finds each group by key" do
      expect(described_class::GROUPS.map { |group| described_class.group(group.key).name }).to eq(["Server Shield", "Integrations"])
    end

    it "is nil for a plugin" do
      expect(described_class.group(:logging)).to be_nil
    end

    it "is nil for no key" do
      expect(described_class.group(nil)).to be_nil
    end
  end

  describe ".unmet_dependent" do
    subject(:dependent) { described_class.unmet_dependent(key, config, enabled_keys:) }

    let(:config) { create(:server_configuration) }
    let(:key) { :logging }
    let(:enabled_keys) { Set[:spam_protection] }

    before do
      config.create_logging_settings!(channel_id: 1)
      config.create_moderation_settings!(staff_role_id: 5)
    end

    context "when a dependent is on and its required plugin is off" do
      it { is_expected.to eq(described_class.find(:spam_protection)) }
    end

    context "when the dependent is off" do
      let(:enabled_keys) { Set[] }

      it { is_expected.to be_nil }
    end

    context "when asking about a group whose staff role was cleared in memory" do
      let(:key) { :moderation }
      let(:enabled_keys) { Set[:logging, :spam_protection] }

      before do
        config.moderation_settings.staff_role_id = nil
      end

      it { is_expected.to eq(described_class.find(:spam_protection)) }
    end

    context "when asking about a group whose members all have their setup" do
      let(:key) { :moderation }
      let(:enabled_keys) { Set[:logging, :spam_protection] }

      it { is_expected.to be_nil }
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

  describe ".visible_sub_plugin_keys" do
    subject(:keys) { described_class.visible_sub_plugin_keys(:moderation, config) }

    let(:config) { create(:server_configuration) }
    let(:paid_sub_plugin) { PluginCatalog::Definition.new(key: :paid_scan, name: "Paid", description: "", parent: :moderation, bespoke: true) }

    before do
      stub_const("PluginCatalog::DEFINITIONS", PluginCatalog::DEFINITIONS + [paid_sub_plugin])
    end

    it "leaves out a bespoke sub-plugin the server was not granted" do
      expect(keys).to eq([:spam_protection, :image_scanning])
    end

    context "when the server was granted it" do
      before { create(:bespoke_plugin_grant, server_configuration: config, plugin_key: :paid_scan) }

      it "includes it" do
        expect(keys).to eq([:spam_protection, :image_scanning, :paid_scan])
      end
    end
  end

  describe ".visible_sub_plugin_keys with a precomputed visible list" do
    subject(:keys) { described_class.visible_sub_plugin_keys(:moderation, nil, visible:) }

    let(:visible) { [described_class.find(:image_scanning), described_class.find(:logging)] }

    it "selects the parent's sub-plugins from it without loading grants" do
      expect(keys).to eq([:image_scanning])
    end
  end

  describe "group wiring" do
    it "puts spam_protection in the moderation group" do
      expect(described_class.find(:spam_protection).parent).to eq(:moderation)
    end

    it "puts image_scanning in the moderation group" do
      expect(described_class.find(:image_scanning).parent).to eq(:moderation)
    end

    it "makes each protection require logging" do
      expect([:spam_protection, :image_scanning].map { |key| described_class.find(key).requires_plugin }).to all(eq(:logging))
    end

    it "keeps groups out of the plugin definitions" do
      expect(described_class.all.map(&:key)).not_to include(:moderation, :integrations)
    end
  end

  describe PluginCatalog::Definition do
    def definition(channel_setting:)
      described_class.new(key: :x, name: "X", description: "", channel_setting:)
    end

    context "when not channel-backed" do
      it "has no prerequisites" do
        expect(definition(channel_setting: nil).prerequisites_met?(double(enabled_plugin_keys: Set[]))).to be(true)
      end
    end

    context "when channel-backed" do
      subject(:check) { definition(channel_setting: :logging_settings).prerequisites_met?(config) }

      context "without a channel" do
        let(:config) { double(logging_settings: nil, enabled_plugin_keys: Set[]) }

        it { is_expected.to be(false) }
      end

      context "with a channel" do
        let(:config) { double(logging_settings: double(channel_id: 5), enabled_plugin_keys: Set[]) }

        it { is_expected.to be(true) }
      end
    end

    context "when requiring another plugin (requires_plugin: :logging)" do
      def requiring_definition
        described_class.new(key: :x, name: "X", description: "", requires_plugin: :logging)
      end

      subject(:check) { requiring_definition.prerequisites_met?(config) }

      context "when required plugin is not enabled" do
        let(:config) { double(enabled_plugin_keys: Set[], logging_settings: double(channel_id: 1)) }

        it { is_expected.to be(false) }
      end

      context "when required plugin is enabled but not set up" do
        let(:config) { double(enabled_plugin_keys: Set[:logging], logging_settings: double(channel_id: nil)) }

        it { is_expected.to be(false) }
      end

      context "when required plugin is enabled and set up" do
        let(:config) { double(enabled_plugin_keys: Set[:logging], logging_settings: double(channel_id: 1)) }

        it { is_expected.to be(true) }
      end
    end

    context "when a group member (parent: :moderation)" do
      subject(:check) { described_class.new(key: :x, name: "X", description: "", parent: :moderation).prerequisites_met?(double(enabled_plugin_keys: Set[])) }

      it "is met with no group state" do
        expect(check).to be(true)
      end
    end

    context "when a prerequisite predicate is set" do
      def definition_with_predicate(predicate)
        described_class.new(key: :x, name: "X", description: "", prerequisite: predicate)
      end

      subject(:check) { definition_with_predicate(predicate).prerequisites_met?(config) }

      context "when predicate returns false" do
        let(:predicate) { ->(_c) { false } }
        let(:config) { double(enabled_plugin_keys: Set[]) }

        it { is_expected.to be(false) }
      end

      context "when predicate returns true" do
        let(:predicate) { ->(_c) { true } }
        let(:config) { double(enabled_plugin_keys: Set[]) }

        it { is_expected.to be(true) }
      end
    end
  end

  describe "Definition#blockers" do
    subject(:blockers) { definition.blockers(config, enabled_keys: Set[]) }

    let(:config) { create(:server_configuration) }
    let(:definition) do
      PluginCatalog::Definition.new(
        key: :x,
        name: "X",
        description: "",
        bespoke: true,
        requires_plugin: :logging,
        channel_setting: :logging_settings,
        prerequisite: ->(_c) { false }
      )
    end

    it "lists every unmet reason in a fixed order" do
      expect(blockers).to eq([:not_granted, :requires_plugin, :channel_missing, :prerequisite])
    end

    context "with a plain definition" do
      let(:definition) { PluginCatalog::Definition.new(key: :x, name: "X", description: "") }

      it { is_expected.to eq([]) }
    end
  end

  describe "protection prerequisite lambdas with real ServerConfiguration" do
    let(:config) { create(:server_configuration, discord_id: 900_000_001) }
    let!(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

    before do
      config.create_logging_settings!(channel_id: 111)
      config.create_moderation_settings!
      create(:plugin_activation, server_configuration: config, plugin: logging_plugin, enabled: false)
        .update_column(:enabled, true)
    end

    [:spam_protection, :image_scanning].each do |key|
      describe ":#{key}" do
        subject(:check) { PluginCatalog.find(key).prerequisites_met?(config) }

        context "when logging is ready and the staff role is set" do
          before do
            config.moderation_settings.update!(staff_role_id: 500)
          end

          it { is_expected.to be(true) }
        end

        context "when logging is ready but no staff role is set" do
          it { is_expected.to be(false) }
        end

        context "when moderation_settings is absent" do
          subject(:check) { PluginCatalog.find(key).prerequisites_met?(config.reload) }

          before do
            config.moderation_settings.destroy!
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end
end
