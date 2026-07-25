# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::PostedMessage do
  subject(:posted_message) { build(:twilight_struggle_posted_message) }

  it "is valid from the factory" do
    expect(posted_message).to be_valid
  end

  describe "discord_channel_id" do
    it "is required" do
      posted_message.discord_channel_id = nil

      expect(posted_message).not_to be_valid
    end
  end

  describe "discord_message_id" do
    it "is required" do
      posted_message.discord_message_id = nil

      expect(posted_message).not_to be_valid
    end
  end

  describe "uniqueness" do
    let!(:existing) { create(:twilight_struggle_posted_message) }

    it "rejects a second posted message for the same game and server" do
      duplicate = build(
        :twilight_struggle_posted_message,
        game: existing.game,
        server_configuration: existing.server_configuration
      )

      expect(duplicate).not_to be_valid
    end

    it "allows the same game for a different server" do
      duplicate = build(:twilight_struggle_posted_message, game: existing.game)

      expect(duplicate).to be_valid
    end

    it "allows the same server for a different game" do
      duplicate = build(:twilight_struggle_posted_message, server_configuration: existing.server_configuration)

      expect(duplicate).to be_valid
    end
  end
end
