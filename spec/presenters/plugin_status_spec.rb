# frozen_string_literal: true

require "rails_helper"

RSpec.describe PluginStatus do
  describe ".rows" do
    subject(:rows) { described_class.rows(server_configuration, access:) }

    include_context "with a bespoke plugin definition"

    let(:server_configuration) { create(:server_configuration) }
    let(:user) { create(:user) }
    let(:access) { PluginAccess.new(user:, server_configuration:, manages_server: true) }

    it "omits an ungranted bespoke plugin" do
      expect(rows.map(&:key)).not_to include(:bespoke_thing)
    end

    context "when the bespoke plugin is granted" do
      before { create(:bespoke_plugin_grant, server_configuration:, plugin_key: bespoke_definition.key) }

      it "includes it" do
        expect(rows.map(&:key)).to include(:bespoke_thing)
      end
    end

    context "when the policy denies the user management of the server" do
      let(:access) { PluginAccess.new(user:, server_configuration:, manages_server: false) }

      it "marks the rows as not manageable" do
        expect(rows.map(&:manageable)).to all(be(false))
      end
    end
  end
end
