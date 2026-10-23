# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::News do
  subject(:items) { news.for_app(440, **arguments) }

  let(:news) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Steam::Client) }
  let(:arguments) { {} }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/news_440.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks the api host for the app's news with the full body" do
    items

    expect(client).to have_received(:get_json).with(
      :api,
      "/ISteamNews/GetNewsForApp/v2/",
      params: {appid: 440, count: 20, maxlength: 0},
      status_errors: anything
    )
  end

  it "treats Steam's 403 for an unknown app id as NotFound" do
    items

    expect(client).to have_received(:get_json).with(
      anything,
      anything,
      params: anything,
      status_errors: {403 => Integrations::NotFound}
    )
  end

  context "with a count" do
    let(:arguments) { {count: 5} }

    it "asks for that many items" do
      items

      expect(client).to have_received(:get_json).with(
        :api,
        anything,
        params: hash_including(count: 5),
        status_errors: anything
      )
    end
  end

  it "returns one NewsItem per entry, in feed order" do
    expect(items.map(&:gid)).to eq(%w[1846651706682902 1846651706682901 1846651706682916])
  end

  it "maps the tagged community post" do
    expect(items.first).to have_attributes(
      gid: "1846651706682902",
      title: "Team Fortress 2 Update Released",
      url: "https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1846651706682902",
      author: "erics",
      contents: start_with("An update to Team Fortress 2 has been released."),
      feed_name: "steam_community_announcements",
      feed_label: "Community Announcements",
      feed_type: 1,
      published_at: Time.zone.at(1792179520),
      tags: ["patchnotes"]
    )
  end

  it "gives an item with no tags an empty list" do
    expect(items.second.tags).to eq([])
  end

  it "turns a blank author into nil" do
    expect(items.third.author).to be_nil
  end

  context "when an item lacks a required key" do
    let(:response) do
      JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/news_440.json").read).tap do |body|
        body["appnews"]["newsitems"].first.delete("title")
      end
    end

    it "raises KeyError, which Http reports as Unavailable" do
      expect { items }.to raise_error(KeyError)
    end
  end
end
