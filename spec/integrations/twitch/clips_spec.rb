# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Clips do
  include ActiveSupport::Testing::TimeHelpers

  subject(:clips_for) { clips.for_broadcaster("23161357", started_at:, ended_at:, featured:) }

  let(:clips) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:started_at) { Time.utc(2026, 10, 1, 12, 0, 0) }
  let(:ended_at) { Time.utc(2026, 10, 31, 12, 0, 0) }
  let(:featured) { nil }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/clips_lirik.json").read) }

  before do
    allow(client).to receive(:get_all) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for every page of the broadcaster's clips inside the window" do
    clips_for

    expect(client).to have_received(:get_all).with(
      "/clips",
      params: {broadcaster_id: "23161357", started_at: "2026-10-01T12:00:00Z", ended_at: "2026-10-31T12:00:00Z", first: 100}
    )
  end

  context "without an end" do
    subject(:clips_for) { clips.for_broadcaster("23161357", started_at:) }

    before { travel_to(ended_at) }

    after { travel_back }

    it "ends the window now, because Twitch otherwise stops a week after the start" do
      clips_for

      expect(client).to have_received(:get_all).with("/clips", params: hash_including(ended_at: "2026-10-31T12:00:00Z"))
    end
  end

  context "when asking only for featured clips" do
    let(:featured) { true }

    it "sends is_featured" do
      clips_for

      expect(client).to have_received(:get_all).with(
        "/clips",
        params: hash_including(is_featured: true)
      )
    end
  end

  context "when asking for non-featured clips" do
    let(:featured) { false }

    it "sends is_featured false" do
      clips_for

      expect(client).to have_received(:get_all).with(
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
        broadcaster_name: "LIRIK",
        creator_name: "Mythriak_",
        category_id: "509658",
        title: "thats crazy",
        created_at: Time.utc(2026, 10, 2, 16, 23, 15),
        thumbnail_url: "https://static-cdn.jtvnw.net/twitch-video-assets/twitch-vap-video-assets-prod-us-west-2/a156412b-e785-41e5-8ddd-e24d1d680bbd/landscape/thumb/thumb-0000000000-480x272.jpg",
        duration: 60
      )
    )
  end

  context "when the clip's game is unset" do
    let(:response) do
      super().tap do |body|
        body.fetch("data").first.merge!("game_id" => "")
      end
    end

    it "has no category" do
      expect(clips_for.first).to have_attributes(category_id: nil)
    end
  end
end
