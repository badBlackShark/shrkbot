# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::EndedAnnouncement do
  subject(:card) { described_class.new(event:, subscription:, history:, vod_url:).card }

  let(:profile_image) { "https://static-cdn.jtvnw.net/jtv_user_pictures/shrkbot-profile_image-300x300.png" }
  let(:watch) { create(:integration_watch, :twitch, image_url: profile_image) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }
  let(:ended_at) { Time.zone.parse("2026-11-01 12:12:00") }
  let(:peak_viewers) { 1204 }
  let(:category_name) { "Hades II" }
  let(:event) do
    create(
      :twitch_stream_ended_event,
      watch:,
      category_name:,
      peak_viewers:,
      duration: 11_520,
      occurred_at: ended_at,
      ended_at: ended_at.iso8601
    )
  end
  let(:history) { [] }
  let(:vod_url) { nil }
  let(:container) { card[:components].find { |component| component[:type] == Bot::Discord::Components::CONTAINER } }
  let(:texts) { container[:components].first[:components] }
  let(:eyebrow) { Bot::Discord::Components.text("-# shrkbot_dev · Was live on Twitch") }
  let(:ended_epoch) { ended_at.to_i }

  def entry(title, category, seconds)
    Feeds::Twitch::TitleHistory::Entry.new(title:, category:, seconds:)
  end

  it "has no lead, so the container comes first" do
    expect(card[:components].first[:type]).to eq(Bot::Discord::Components::CONTAINER)
  end

  it "is grey" do
    expect(container[:accent_color]).to eq(0x80848e)
  end

  it "has no image" do
    expect(container[:components].map { |block| block[:type] }).not_to include(Bot::Discord::Components::MEDIA_GALLERY)
  end

  it "keeps the profile picture beside the texts" do
    expect(container[:components].first[:accessory]).to eq(Bot::Discord::Components.thumbnail(profile_image))
  end

  context "without a VOD" do
    it "has no action row" do
      expect(card[:components].map { |component| component[:type] }).not_to include(Bot::Discord::Components::ACTION_ROW)
    end
  end

  context "with a VOD" do
    let(:vod_url) { "https://www.twitch.tv/videos/1" }

    it "links it" do
      expect(card[:components].last[:components]).to eq(
        [Bot::Discord::Components.link_button(url: vod_url, label: "Watch the VOD")]
      )
    end
  end

  context "with a single entry" do
    let(:history) { [entry("Hades II blind run, day 3", "Hades II", 11_520)] }

    it "summarises the stream under the stream's title" do
      expect(texts).to eq([
        eyebrow,
        Bot::Discord::Components.text("## Hades II blind run, day 3"),
        Bot::Discord::Components.text("Streamed **Hades II** for about 3 h 12 min\n-# At least 1,204 viewers at the peak · ended <t:#{ended_epoch}:R>")
      ])
    end

    context "when the channel had no category" do
      let(:category_name) { nil }

      it "leaves the category out" do
        expect(texts.last[:content]).to start_with("Streamed for about 3 h 12 min\n")
      end
    end
  end

  context "with a title history" do
    let(:history) do
      [
        entry("Hades II blind run", "Hades II", 3600),
        entry("Chatting", "Just Chatting", 5400)
      ]
    end

    it "headlines the total and lists each title, showing a category the title lacks" do
      expect(texts[1]).to eq(Bot::Discord::Components.text("## Streamed for about 3 h 12 min"))
      expect(texts.last[:content]).to eq(
        "- Hades II blind run · about 1 h\n" \
        "- Chatting · **Just Chatting** · about 1 h 30 min\n" \
        "-# At least 1,204 viewers at the peak · ended <t:#{ended_epoch}:R>"
      )
    end

    context "with more than 15 entries" do
      let(:history) { Array.new(18) { |index| entry("Title #{index}", nil, 600) } }

      it "lists 15 and counts the rest" do
        lines = texts.last[:content].lines.map(&:chomp)

        expect(lines.first(15)).to all(start_with("- Title"))
        expect(lines[15]).to eq("and 3 more")
        expect(lines.size).to eq(17)
      end
    end
  end

  describe "the peak line" do
    subject(:stats) { texts.last[:content].lines.last }

    context "without a peak" do
      let(:peak_viewers) { nil }

      it { is_expected.to eq("-# Ended <t:#{ended_epoch}:R>") }
    end

    context "when the subscription hides viewers" do
      before { subscription.settings.update!(show_viewers: false) }

      it { is_expected.to eq("-# Ended <t:#{ended_epoch}:R>") }
    end
  end

  context "when the watch has no profile picture" do
    let(:profile_image) { nil }

    it "puts the texts straight into the container" do
      expect(container[:components].map { |block| block[:type] }).to all(eq(Bot::Discord::Components::TEXT_DISPLAY))
    end
  end
end
