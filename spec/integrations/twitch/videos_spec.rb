# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Videos do
  subject(:videos_for_user) { videos.for_user("141981764") }

  let(:videos) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/videos_twitchdev.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the user's videos of every type" do
    videos_for_user

    expect(client).to have_received(:get_json).with(
      "/videos",
      params: {user_id: "141981764", type: "all", first: 20}
    )
  end

  it "passes the type and page size through" do
    videos.for_user("141981764", type: "archive", first: 5)

    expect(client).to have_received(:get_json).with(
      "/videos",
      params: {user_id: "141981764", type: "archive", first: 5}
    )
  end

  it "maps the first video, filling the thumbnail size and reading the duration as seconds" do
    expect(videos_for_user.first).to eq(
      Integrations::Twitch::Video.new(
        id: "2277656159",
        stream_id: "44926619787",
        user_id: "141981764",
        title: "Standard Output // October 16, 2024",
        description: "",
        created_at: Time.utc(2024, 10, 16, 18, 31, 23),
        published_at: Time.utc(2024, 10, 16, 18, 31, 23),
        url: "https://www.twitch.tv/videos/2277656159",
        thumbnail_url: "https://static-cdn.jtvnw.net/cf_vods/d2nvs31859zcd8/30f3738ff535638f66df_twitchdev_44926619787_1729103477//thumb/thumb0-320x180.jpg",
        type: "archive",
        duration: 3238
      )
    )
  end

  {
    "1h4m35s" => 3875,
    "3m21s" => 201,
    "45s" => 45,
    "2h" => 7200,
    "1h0m5s" => 3605
  }.each do |text, seconds|
    context "when the duration is #{text}" do
      let(:response) do
        super().tap { |body| body.fetch("data").first["duration"] = text }
      end

      it "reads #{seconds} seconds" do
        expect(videos_for_user.first.duration).to eq(seconds)
      end
    end
  end

  context "when the duration is not in Twitch's format" do
    let(:response) do
      super().tap { |body| body.fetch("data").first["duration"] = "an hour" }
    end

    it "raises Unavailable" do
      expect { videos_for_user }.to raise_error(Integrations::Unavailable, /unreadable video duration/)
    end
  end

  context "when the video has no stream" do
    let(:response) do
      super().tap { |body| body.fetch("data").first["stream_id"] = "" }
    end

    it "has no stream id" do
      expect(videos_for_user.first.stream_id).to be_nil
    end
  end
end
