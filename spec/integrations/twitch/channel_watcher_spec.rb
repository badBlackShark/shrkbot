# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::ChannelWatcher do
  let(:users) { instance_double(Integrations::Twitch::Users) }
  let(:user) { Integrations::Twitch::User.new(id: "141981764", login: "twitchdev", display_name: "TwitchDev", profile_image_url: "https://example.test/a.png") }
  let(:target) { Integrations::Target.new(external_id: "141981764", name: "TwitchDev", image_url: "https://example.test/a.png") }

  describe ".resolve" do
    subject(:resolved) { described_class.resolve("https://twitch.tv/TwitchDev", users:) }

    before do
      allow(users).to receive(:find_by_login).with("twitchdev").and_return(user)
    end

    it "looks the parsed login up and maps the user to a target" do
      expect(resolved).to eq(target)
    end
  end

  describe ".refresh" do
    subject(:refreshed) { described_class.refresh(["141981764"], users:) }

    before do
      allow(users).to receive(:for).with(["141981764"]).and_return([user])
    end

    it "maps each user to a target" do
      expect(refreshed).to eq([target])
    end
  end
end
