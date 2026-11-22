# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Twitch::Watches::Discover do
  subject(:result) { described_class.call(streams:) }

  let(:streams) { [stream("1"), stream("2"), stream("3"), stream("1")] }
  let(:users) { instance_double(Integrations::Twitch::Users) }
  let(:user) do
    Integrations::Twitch::User.new(id: "2", login: "newone", display_name: "New One", profile_image_url: "https://example.test/new.png")
  end
  let!(:known) { create(:integration_watch, :twitch, external_id: "1", name: "Known") }

  before do
    allow(Integrations::Twitch::Users).to receive(:new).and_return(users)
    allow(users).to receive(:for).with(%w[2 3]).and_return([user])
  end

  def stream(user_id)
    instance_double(Integrations::Twitch::Stream, user_id:)
  end

  it "reuses the existing watch and creates the missing one from the user" do
    expect { result }.to change(Integrations::Watch, :count).by(1)
    expect(result.value.keys).to contain_exactly("1", "2")
    expect(result.value["1"]).to eq(known)
    expect(result.value["2"]).to have_attributes(
      watcher: "Integrations::Twitch::ChannelWatcher",
      name: "New One",
      image_url: "https://example.test/new.png",
      url: "https://www.twitch.tv/newone"
    )
  end

  context "when nothing is missing" do
    let(:streams) { [stream("1")] }

    it "asks Twitch for nothing" do
      result

      expect(users).not_to have_received(:for)
    end
  end

  context "when a follow created the watch while Twitch was asked" do
    before do
      allow(users).to receive(:for).with(%w[2 3]) do
        create(:integration_watch, :twitch, external_id: "2", name: "Followed First")
        [user]
      end
    end

    it "keeps that watch instead of failing" do
      expect(result.value["2"].name).to eq("Followed First")
    end
  end
end
