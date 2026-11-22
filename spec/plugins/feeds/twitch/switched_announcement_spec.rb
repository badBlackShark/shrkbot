# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::SwitchedAnnouncement do
  subject(:card) { described_class.new(event:, subscription:, ended_at:).card }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:started_at) { Time.zone.parse("2026-11-01 09:00:00") }
  let(:category_name) { "Just Chatting" }
  let(:ended_at) { nil }
  let(:event) { create(:twitch_stream_updated_event, watch:, category_name:, started_at: started_at.iso8601) }
  let(:container) { card[:components].find { |component| component[:type] == Bot::Discord::Components::CONTAINER } }
  let(:texts) { container[:components].first[:components] }

  it "has no lead, so the container comes first" do
    expect(card[:components].first[:type]).to eq(Bot::Discord::Components::CONTAINER)
  end

  it "is grey" do
    expect(container[:accent_color]).to eq(0x80848e)
  end

  it "keeps the profile picture beside the texts" do
    expect(container[:components].first[:accessory]).to eq(Bot::Discord::Components.thumbnail(profile_image))
  end

  it "names the new category under the stream's title" do
    expect(texts).to eq([
      Bot::Discord::Components.text("-# shrkbot_dev · Live on Twitch"),
      Bot::Discord::Components.text("## #{event.title}"),
      Bot::Discord::Components.text("Switched to **Just Chatting**\n-# Started <t:#{started_at.to_i}:R>")
    ])
  end

  it "still links to the live stream" do
    expect(card[:components].last[:components]).to eq(
      [Bot::Discord::Components.link_button(url: "https://www.twitch.tv/shrkbot_dev", label: "Watch on Twitch")]
    )
  end

  it "has no footer while the stream is live" do
    expect(container[:components].size).to eq(1)
  end

  context "when the stream ended while switched away" do
    let(:ended_at) { "2026-11-01T12:00:00Z" }

    it "stamps the end below the texts" do
      expect(container[:components].last).to eq(Bot::Discord::Components.text("-# Stream ended <t:#{Time.iso8601(ended_at).to_i}:R>"))
    end
  end

  context "without a category" do
    let(:category_name) { nil }

    it "says it switched away from the chosen ones" do
      expect(texts.last[:content]).to start_with("Switched away from the chosen categories\n")
    end
  end
end
