# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::SubscriptionPaths do
  let(:server_configuration) { create(:server_configuration) }
  let(:discord_id) { server_configuration.discord_id }

  describe ".plugin_for" do
    subject(:path) { described_class.plugin_for(server_configuration, source) }

    context "when the plugin has one source" do
      let(:source) { Feeds::Steam }

      it "is the plugin page" do
        expect(path).to eq("/servers/#{discord_id}/steam")
      end
    end

    context "when the plugin has several sources" do
      let(:source) { Feeds::TwitchCategory }

      it "opens the tab of that source" do
        expect(path).to eq("/servers/#{discord_id}/twitch?tab=twitch_category")
      end
    end
  end
end
