# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Clips do
  subject(:clips_for) { clips.for_broadcaster("23161357", started_at:, featured:) }

  let(:clips) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:started_at) { Time.utc(2026, 10, 1, 12, 0, 0) }
  let(:featured) { nil }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/clips_lirik.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the broadcaster's clips since the given time" do
    clips_for

    expect(client).to have_received(:get_json).with(
      "/clips",
      params: {broadcaster_id: "23161357", started_at: "2026-10-01T12:00:00Z", first: 20}
    )
  end

  context "when asking only for featured clips" do
    let(:featured) { true }

    it "sends is_featured" do
      clips_for

      expect(client).to have_received(:get_json).with(
        "/clips",
        params: hash_including(is_featured: true)
      )
    end
  end

  context "when asking for non-featured clips" do
    let(:featured) { false }

    it "sends is_featured false" do
      clips_for

      expect(client).to have_received(:get_json).with(
        "/clips",
        params: hash_including(is_featured: false)
      )
    end
  end

  it "returns every clip in Twitch's order" do
    expect(clips_for.map(&:id)).to eq(
      %w[
        PiercingFragileHornetPJSalt-MWN6RC3-Dp3tHDsx
        CleverGrotesqueSkunkHumbleLife-3jLXIILvcjBHp2zu
        BoringBlatantJalapenoGOWSkull-nXTeq-y9ikR7my5_
      ]
    )
  end

  it "maps the first clip" do
    expect(clips_for.first).to eq(
      Integrations::Twitch::Clip.new(
        id: "PiercingFragileHornetPJSalt-MWN6RC3-Dp3tHDsx",
        url: "https://www.twitch.tv/lirik/clip/PiercingFragileHornetPJSalt-MWN6RC3-Dp3tHDsx",
        broadcaster_id: "23161357",
        creator_name: "Mythriak_",
        video_id: "2889882220",
        category_id: "509658",
        title: "thats crazy",
        view_count: 879,
        created_at: Time.utc(2026, 10, 2, 16, 23, 15),
        thumbnail_url: "https://static-cdn.jtvnw.net/twitch-video-assets/twitch-vap-video-assets-prod-us-west-2/a156412b-e785-41e5-8ddd-e24d1d680bbd/landscape/thumb/thumb-0000000000-480x272.jpg",
        duration: 60,
        featured: false
      )
    )
  end

  context "when the clip's VOD is gone or the game unset" do
    let(:response) do
      super().tap do |body|
        body.fetch("data").first.merge!("video_id" => "", "game_id" => "")
      end
    end

    it "has no video and no category" do
      expect(clips_for.first).to have_attributes(video_id: nil, category_id: nil)
    end
  end
end
