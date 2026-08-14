# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreviewData do
  describe ".guild" do
    subject(:guild) { described_class.guild }

    it "exposes the canonical negative discord_id" do
      expect(guild[:discord_id]).to eq(-1)
    end

    it "exposes the guild name" do
      expect(guild[:name]).to eq("The Reef")
    end
  end

  describe ".channels" do
    subject(:channels) { described_class.channels }

    it "exposes every channel from the file" do
      expect(channels.map { |channel| channel[:discord_id] }).to match_array([100, 101, 102, 103, 104, 105, 106, 107])
    end

    it "types a category channel as ServerChannel::CATEGORY_TYPE" do
      category = channels.find { |channel| channel[:discord_id] == 100 }

      expect(category[:channel_type]).to eq(ServerChannel::CATEGORY_TYPE)
    end

    it "types a text channel as 0" do
      text_channel = channels.find { |channel| channel[:discord_id] == 101 }

      expect(text_channel[:channel_type]).to eq(0)
    end

    it "gives every channel an empty overwrites list" do
      expect(channels).to all(include(overwrites: []))
    end
  end

  describe ".roles" do
    subject(:roles) { described_class.roles }

    it "exposes every role from the file" do
      expect(roles.map { |role| role[:discord_id] }).to match_array([-1, 201, 202, 203, 204, 205, 206, 207, 208])
    end
  end

  describe ".plugins" do
    subject(:plugin_keys) { described_class.plugins.map { |entry| entry[:plugin].to_sym } }

    it "has demo data for every non-bespoke plugin catalog definition, so a new plugin can't ship without it" do
      non_bespoke_keys = PluginCatalog.all.reject(&:bespoke).map(&:key)

      expect(plugin_keys).to match_array(non_bespoke_keys)
    end
  end
end
