# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Streams do
  subject(:live) { streams.live(ids) }

  let(:streams) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:ids) { %w[92038375 36029255] }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/streams.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the users' live streams, 100 to a page" do
    live

    expect(client).to have_received(:get_json).with("/streams", params: {user_id: ids, first: 100})
  end

  it "returns a stream per live channel" do
    expect(live.map(&:user_login)).to eq(%w[caedrel riotgames])
  end

  it "maps the first stream, keeping the thumbnail template" do
    expect(live.first).to eq(
      Integrations::Twitch::Stream.new(
        id: "318183054051",
        user_id: "92038375",
        user_login: "caedrel",
        user_name: "Caedrel",
        category_id: "21779",
        category_name: "League of Legends",
        title: "🔴WORLDS 2026 G2 VS HLE ELIMINATION🔴",
        viewer_count: 307518,
        started_at: Time.utc(2026, 10, 30, 14, 55, 54),
        thumbnail_url: "https://static-cdn.jtvnw.net/previews-ttv/live_user_caedrel-{width}x{height}.jpg"
      )
    )
  end

  context "when the stream has no category" do
    let(:response) do
      super().tap do |body|
        body.fetch("data").first.merge!("game_id" => "", "game_name" => "")
      end
    end

    it "has no category" do
      expect(live.first).to have_attributes(category_id: nil, category_name: nil)
    end
  end

  context "with more than 100 ids" do
    let(:ids) { (1..101).map(&:to_s) }

    it "asks in slices of 100" do
      live

      expect(client).to have_received(:get_json).with("/streams", params: {user_id: ids.first(100), first: 100})
      expect(client).to have_received(:get_json).with("/streams", params: {user_id: ["101"], first: 100})
    end
  end

  context "without ids" do
    let(:ids) { [] }

    it "returns nothing and makes no request" do
      expect(live).to eq([])
      expect(client).not_to have_received(:get_json)
    end
  end
end
