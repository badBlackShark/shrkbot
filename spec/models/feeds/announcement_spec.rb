# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Announcement do
  subject(:announcement) { described_class.new(event:, subscription:, thumbnail:) }

  let(:thumbnail) { nil }
  let(:watch) { create(:integration_watch, name: "Team Fortress 2") }
  let(:role_id) { 4242 }
  let(:body_length) { "preview" }
  let(:subscription) { create(:feed_subscription, watch:, body_length:) }
  let(:template) { nil }
  let(:event) { create(:steam_news_event, watch:, title: "Smissmas 2026", body: "Snow is falling.", image_urls: []) }
  let(:event_type) { event.type }

  before do
    create(:feed_subscribed_event, subscription:, event_type:, template:, role_id:)
  end

  describe ".eyebrow" do
    it "labels patch notes, announcements and falls back to the feed" do
      expect(described_class.eyebrow("Hades", "Integrations::Steam::PatchNotesPublished", "Feed")).to eq("Hades · Patch notes")
      expect(described_class.eyebrow("Hades", "Integrations::Steam::AnnouncementPublished", "Feed")).to eq("Hades · Announcement")
      expect(described_class.eyebrow("Hades", "Integrations::Steam::ArticlePublished", "PC Gamer")).to eq("Hades · PC Gamer")
    end
  end

  describe "#allowed_mentions" do
    subject(:allowed_mentions) { announcement.allowed_mentions }

    context "when the subscription follows two types with different roles" do
      let(:other_type) { "Integrations::Steam::AnnouncementPublished" }

      before do
        create(:feed_subscribed_event, subscription:, event_type: other_type, role_id: 9999)
      end

      it "allows only the role of the event's type" do
        expect(allowed_mentions).to eq({parse: [], roles: [4242]})
      end

      it "mentions only the role of the event's type" do
        expect(announcement.subject).to eq("<@&4242> Team Fortress 2 · Patch notes: Smissmas 2026")
      end
    end

    context "without a role on the type" do
      let(:role_id) { nil }

      it "allows no mention" do
        expect(allowed_mentions).to eq({parse: []})
      end
    end

    context "when the subscription no longer follows the event's type" do
      let(:event_type) { "Integrations::Steam::AnnouncementPublished" }

      it "allows no mention and mentions no role" do
        expect(allowed_mentions).to eq({parse: []})
        expect(announcement.subject).to eq("Team Fortress 2 · Patch notes: Smissmas 2026")
      end
    end
  end

  describe "#subject" do
    subject(:subject_line) { announcement.subject }

    context "without a custom message" do
      it "is the role and the headline" do
        expect(subject_line).to eq("<@&4242> Team Fortress 2 · Patch notes: Smissmas 2026")
      end

      context "for an announcement" do
        let(:event) { create(:steam_announcement_event, watch:, title: "Smissmas 2026") }

        it "reads as an announcement" do
          expect(subject_line).to eq("<@&4242> Team Fortress 2 · Announcement: Smissmas 2026")
        end
      end

      context "for an article" do
        let(:event) { create(:steam_article_event, watch:, title: "Smissmas 2026", feed_label: "Rock Paper Shotgun") }

        it "leads with the feed" do
          expect(subject_line).to eq("<@&4242> Team Fortress 2 · Rock Paper Shotgun: Smissmas 2026")
        end
      end
    end

    context "with a custom message" do
      let(:template) { "Patch day for {game}!" }

      it "is the role and the rendered text" do
        expect(subject_line).to eq("<@&4242> Patch day for Team Fortress 2!")
      end
    end

    context "with a stored template that still has the removed title token" do
      let(:template) { "{title}" }

      it "leaves it literal" do
        expect(subject_line).to eq("<@&4242> {title}")
      end
    end

    context "without a role" do
      let(:role_id) { nil }

      it "starts with the headline, without a leading space" do
        expect(subject_line).to eq("Team Fortress 2 · Patch notes: Smissmas 2026")
      end
    end

    context "when the text is longer than Discord allows" do
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
      expect(fallback).to eq("<@&4242> Team Fortress 2 · Patch notes: Smissmas 2026\nhttps://store.steampowered.com/news/286827/")
    end

    context "when the subject already fills Discord's limit" do
      let(:event) { create(:steam_news_event, watch:, title: "word " * 600) }

      it "stays within 2000 characters and keeps the whole link" do
        expect(fallback.length).to be <= 2000
        expect(fallback).to end_with("\nhttps://store.steampowered.com/news/286827/")
      end
    end
  end

  describe "#attachments" do
    subject(:attachments) { announcement.attachments }

    context "with thumbnail bytes" do
      let(:thumbnail) { "webp-bytes" }

      it "is one upload named thumbnail.webp carrying them" do
        expect(attachments.size).to eq(1)
        expect(attachments.first).to be_a(Bot::Discord::FileUpload)
        expect(attachments.first.original_filename).to eq("thumbnail.webp")
        expect(attachments.first.read).to eq("webp-bytes")
      end
    end

    context "without a thumbnail" do
      it "is nil" do
        expect(attachments).to be_nil
      end
    end
  end

  describe "#card" do
    subject(:card) { announcement.card }

    let(:lead) { card[:components].first }
    let(:container) { card[:components].find { |component| component[:type] == Bot::Discord::Components::CONTAINER } }
    let(:action_row) { card[:components].last }
    let(:texts) { container[:components].filter_map { |block| block[:content] } }

    it "is a Components V2 message" do
      expect(card[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
    end

    it "puts the role mention above the container" do
      expect(lead).to eq(Bot::Discord::Components.text("<@&4242>"))
      expect(card[:components].second).to eq(container)
    end

    context "with a custom message" do
      let(:template) { "Patch day for {game}!" }

      it "adds it to the lead line" do
        expect(lead).to eq(Bot::Discord::Components.text("<@&4242> Patch day for Team Fortress 2!"))
      end

      context "without a role" do
        let(:role_id) { nil }

        it "is the lead line alone" do
          expect(lead).to eq(Bot::Discord::Components.text("Patch day for Team Fortress 2!"))
        end
      end
    end

    context "with neither a role nor a custom message" do
      let(:role_id) { nil }

      it "starts with the container" do
        expect(card[:components].first).to eq(container)
        expect(card[:components].map { |component| component[:type] }).to eq([Bot::Discord::Components::CONTAINER, Bot::Discord::Components::ACTION_ROW])
      end
    end

    it "carries the eyebrow, the heading and the excerpt" do
      expect(container[:components]).to eq(
        [
          Bot::Discord::Components.text("-# Team Fortress 2 · Patch notes"),
          Bot::Discord::Components.text("## Smissmas 2026"),
          Bot::Discord::Components.text("Snow is falling.")
        ]
      )
    end

    context "with thumbnail bytes" do
      let(:thumbnail) { "webp-bytes" }

      it "shows the attachment as the thumbnail of a section around the eyebrow and heading" do
        expect(container[:components].first).to eq(
          Bot::Discord::Components.section(
            [Bot::Discord::Components.text("-# Team Fortress 2 · Patch notes"), Bot::Discord::Components.text("## Smissmas 2026")],
            accessory: Bot::Discord::Components.thumbnail("attachment://thumbnail.webp")
          )
        )
      end
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
        expect(texts).to eq(["-# Team Fortress 2 · Patch notes", "## Smissmas 2026"])
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

      context "with a lead line and title at their limits" do
        let(:template) { "word " * 600 }
        let(:event) { create(:steam_news_event, watch:, title: "t" * 300, body: "word " * 2000) }

        it "keeps the text of the whole message within Discord's 4000" do
          all_texts = texts + [lead[:content]]

          expect(all_texts.sum(&:length)).to be <= 4000
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
