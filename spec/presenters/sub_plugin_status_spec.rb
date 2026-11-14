# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubPluginStatus do
  describe ".rows" do
    subject(:rows) { described_class.rows(server_configuration, parent: :moderation) }

    let(:server_configuration) { create(:server_configuration) }
    let(:staff_role_id) { 701 }

    let(:logging) { create(:plugin, key: "logging", name: "Logging") }
    let(:spam_protection) { create(:plugin, key: "spam_protection", name: "Spam") }

    before do
      server_configuration.create_moderation_settings!(staff_role_id:)
      server_configuration.create_logging_settings!(channel_id: 11)
      create(:plugin_activation, server_configuration:, plugin: logging).update_column(:enabled, true)
      create(:plugin_activation, server_configuration:, plugin: spam_protection).update_column(:enabled, true)
    end

    it "lists the parent's sub-plugins in catalog order" do
      expect(rows.map(&:key)).to eq([:spam_protection, :image_scanning])
    end

    it "takes name and description from the catalog" do
      expect(rows.first).to have_attributes(
        name: PluginCatalog.find(:spam_protection).name,
        description: PluginCatalog.find(:spam_protection).description
      )
    end

    it "marks only the enabled sub-plugins as enabled" do
      expect(rows.map(&:enabled)).to eq([true, false])
    end

    it "marks every sub-plugin as configured while its prerequisites hold" do
      expect(rows.map(&:configured)).to eq([true, true])
    end

    context "when a prerequisite is missing" do
      let(:staff_role_id) { nil }

      it "marks the sub-plugins as not configured" do
        expect(rows.map(&:configured)).to eq([false, false])
      end
    end
  end
end
