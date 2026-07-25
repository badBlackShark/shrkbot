# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginStatus do
  describe ".rows" do
    subject(:rows) { described_class.rows(server_configuration) }

    include_context "with a bespoke plugin definition"

    let(:server_configuration) { create(:server_configuration) }

    it "omits an ungranted bespoke plugin" do
      expect(rows.map(&:key)).not_to include(:bespoke_thing)
    end

    context "when the bespoke plugin is granted" do
      before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: bespoke_definition.key) }

      it "includes it" do
        expect(rows.map(&:key)).to include(:bespoke_thing)
      end
    end
  end
end
