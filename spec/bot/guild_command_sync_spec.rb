# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe GuildCommandSync do
  let(:profile) { double("profile", id: 42) }
  let(:bot) { double("bot", token: "Bot tok123", profile:) }
  let(:discord_id) { 12_345 }
  let(:payloads) { [{name: "ping", description: "test", type: 1}] }

  before do
    allow(GuildCommandSet).to receive(:new).with(discord_id).and_return(
      instance_double(GuildCommandSet, payloads:)
    )
  end

  describe "#sync" do
    subject(:sync) { described_class.new(bot).sync(discord_id) }

    it "calls bulk_overwrite_guild_commands with the right arguments" do
      expect(Discordrb::API::Application).to receive(:bulk_overwrite_guild_commands).with(
        "Bot tok123",
        42,
        discord_id,
        payloads
      )
      sync
    end

    context "when the API call raises" do
      before do
        allow(Discordrb::API::Application).to receive(:bulk_overwrite_guild_commands).and_raise(
          StandardError, "network failure"
        )
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        sync
        expect(Rails.logger).to have_received(:error).with(
          a_string_including("[GuildCommandSync]", discord_id.to_s, "StandardError", "network failure")
        )
      end

      it "does not re-raise" do
        expect { sync }.not_to raise_error
      end
    end
  end
end
