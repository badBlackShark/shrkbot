# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Announcement do
  subject(:announcement) { described_class.new(event:, subscription:) }

  let(:watch) { create(:integration_watch, name: "Team Fortress 2") }
  let(:role_id) { 4242 }
  let(:body_length) { "preview" }
  let(:subscription) { create(:feed_subscription, watch:, role_id:, body_length:) }
  let(:template) { nil }
  let(:event) { create(:steam_news_event, watch:, title: "Smissmas 2026", body: "Snow is falling.", image_urls: []) }
  let(:event_type) { event.type }

  before do
    create(:feed_subscribed_event, subscription:, event_type:, template:)
  end

  describe "#subject" do
    subject(:subject_line) { announcement.subject }

    context "with the default template per event class" do
      it "reads as patch notes" do
        expect(subject_line).to eq("<@&4242> New Team Fortress 2 patch notes: Smissmas 2026")
      end

      context "for an announcement" do
        let(:event) { create(:steam_announcement_event, watch:, title: "Smissmas 2026") }

        it "reads as an announcement" do
          expect(subject_line).to eq("<@&4242> New Team Fortress 2 announcement: Smissmas 2026")
        end
      end

      context "for an article" do
        let(:event) { create(:steam_article_event, watch:, title: "Smissmas 2026", feed_label: "Rock Paper Shotgun") }

        it "leads with the feed" do
          expect(subject_line).to eq("<@&4242> Rock Paper Shotgun: Smissmas 2026")
        end
      end
    end

    context "with a custom template" do
      let(:template) { "{game} by {author}: {title} {url}" }

      it "renders every token" do
        expect(subject_line).to eq("Team Fortress 2 by Valve: Smissmas 2026 https://store.steampowered.com/news/286827/")
      end
    end

    context "without a role" do
      let(:role_id) { nil }

      it "drops the role token and the space it leaves" do
        expect(subject_line).to eq("New Team Fortress 2 patch notes: Smissmas 2026")
      end
    end

    context "when the rendered text is longer than Discord allows" do
      let(:event) { create(:steam_news_event, watch:, title: "word " * 600) }

      it "truncates to 2000 characters" do
        expect(subject_line.length).to be <= 2000
        expect(subject_line).to end_with("…")
      end
    end
  end

  describe "#fallback" do
    subject(:fallback) { announcement.fallback }

    it "is the subject followed by the link" do
      expect(fallback).to eq("<@&4242> New Team Fortress 2 patch notes: Smissmas 2026\nhttps://store.steampowered.com/news/286827/")
    end

    context "when the subject already fills Discord's limit" do
      let(:event) { create(:steam_news_event, watch:, title: "word " * 600) }

      it "stays within 2000 characters and keeps the whole link" do
        expect(fallback.length).to be <= 2000
        expect(fallback).to end_with("\nhttps://store.steampowered.com/news/286827/")
      end
    end
  end

  describe "#card" do
    subject(:card) { announcement.card }

    let(:container) { card[:components].first }
    let(:action_row) { card[:components].last }

    it "is a Components V2 message" do
      expect(card[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
    end

    it "carries the subject, the heading and the excerpt" do
      expect(container[:components]).to eq(
        [
          Bot::Discord::Components.text("<@&4242> New Team Fortress 2 patch notes: Smissmas 2026"),
          Bot::Discord::Components.text("## Smissmas 2026"),
          Bot::Discord::Components.text("Snow is falling.")
        ]
      )
    end

    it "links the original post" do
      expect(action_row[:components]).to eq(
        [Bot::Discord::Components.link_button(url: "https://store.steampowered.com/news/286827/", label: "Read the full post")]
      )
    end

    context "when the post has images" do
      let(:event) { create(:steam_news_event, watch:, title: "Smissmas 2026", body: "Snow.", image_urls: ["https://img/1.png", "https://img/2.png"]) }

      it "shows the first one only" do
        expect(container[:components].last).to eq(Bot::Discord::Components.media_gallery(["https://img/1.png"]))
      end
    end

    context "when the body is blank" do
      let(:event) { create(:steam_news_event, watch:, title: "Smissmas 2026", body: "") }

      it "omits the excerpt block" do
        expect(container[:components].map { |block| block[:content] }).to eq(
          ["<@&4242> New Team Fortress 2 patch notes: Smissmas 2026", "## Smissmas 2026"]
        )
      end
    end

    context "when the title is longer than a heading should be" do
      let(:event) { create(:steam_news_event, watch:, title: "word " * 100) }

      it "truncates it to 256 characters" do
        expect(container[:components].second[:content].delete_prefix("## ").length).to be <= 256
      end
    end

    context "with the full body length" do
      let(:body_length) { "full" }
      let(:event) { create(:steam_news_event, watch:, body: "word " * 300) }

      it "keeps more than the preview would" do
        expect(container[:components].third[:content].length).to be > 500
      end

      context "with a subject and title at their limits" do
        let(:template) { "word " * 600 }
        let(:event) { create(:steam_news_event, watch:, title: "t" * 300, body: "word " * 2000) }

        it "keeps the text of the whole message within Discord's 4000" do
          texts = container[:components].filter_map { |block| block[:content] }

          expect(texts.sum(&:length)).to be <= 4000
          expect(texts.last.length).to be > 1000
        end
      end
    end

    context "with the preview body length" do
      let(:event) { create(:steam_news_event, watch:, body: "word " * 300) }

      it "cuts the body down" do
        expect(container[:components].third[:content].length).to be <= 501
      end
    end
  end
end
