# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::PostMessage do
  let(:role_id) { 111 }
  let(:creator_id) { 222 }
  let(:start_ts) { 1_700_000_000 }
  let(:message) { "let's go" }
  let(:joiner_ids) { [333, 444] }
  let(:started) { false }

  describe ".render" do
    subject(:rendered) do
      described_class.render(
        role_id:,
        creator_id:,
        start_ts:,
        message:,
        joiner_ids:,
        started:
      )
    end

    let(:container) { rendered[:components].first }
    let(:text_blocks) { container[:components] }
    let(:action_row) { rendered[:components].second }

    it "sets the Components V2 flag" do
      expect(rendered[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
    end

    it "renders the Join and Done looking buttons with the 3-arg custom_ids" do
      buttons = action_row[:components]

      expect(buttons.map { |b| b[:custom_id] }).to eq([
        Lfg::CustomId.join(creator_id, start_ts, role_id),
        Lfg::CustomId.done(creator_id, start_ts, role_id)
      ])
    end

    context "when a message is present" do
      let(:message) { "let's go" }

      it "renders heading, note, and joiner blocks" do
        expect(text_blocks.size).to eq(3)
        expect(text_blocks).to all(include(type: Bot::Discord::Components::TEXT_DISPLAY))
      end

      it "puts the message verbatim as its own block" do
        expect(text_blocks.second[:content]).to eq("let's go")
      end
    end

    context "when no message is present" do
      let(:message) { nil }

      it "renders only heading and joiner blocks" do
        expect(text_blocks.size).to eq(2)
        expect(text_blocks).to all(include(type: Bot::Discord::Components::TEXT_DISPLAY))
      end
    end

    context "when the game has not started" do
      let(:started) { false }

      it "uses gathering wording" do
        expect(text_blocks.first[:content]).to include("is looking to play, starting")
        expect(text_blocks.first[:content]).to include("Click **Join**")
      end
    end

    context "when the game has started" do
      let(:started) { true }

      it "uses started wording" do
        expect(text_blocks.first[:content]).to include("is looking for a game right now")
      end
    end

    it "has no emoji in the heading" do
      expect(text_blocks.first[:content]).not_to match(/\p{Emoji_Presentation}/)
    end

    context "with no joiners" do
      let(:joiner_ids) { [] }

      it "shows the empty-joiners copy as the last block" do
        expect(text_blocks.last[:content]).to eq("No one's in yet.")
      end
    end

    context "with joiners" do
      let(:joiner_ids) { [333, 444] }

      it "lists the joiner count and mentions as the last block" do
        expect(text_blocks.last[:content]).to eq("**In (2):** <@333> <@444>")
      end
    end
  end

  describe ".parse" do
    subject(:parsed) { described_class.parse(echo) }

    let(:rendered) do
      described_class.render(
        role_id:,
        creator_id:,
        start_ts:,
        message:,
        joiner_ids:,
        started:
      )
    end
    let(:echo) { JSON.parse(rendered.to_json) }

    context "when round-tripped through a rendered message with a note" do
      let(:message) { "let's go" }
      let(:joiner_ids) { [333, 444] }

      it "recovers exactly joiner_ids and message" do
        expect(parsed).to eq(
          joiner_ids: [333, 444],
          message: "let's go"
        )
      end
    end

    context "when no message was set" do
      let(:message) { nil }

      it "recovers a nil message" do
        expect(parsed[:message]).to be_nil
      end
    end

    context "when there are no joiners" do
      let(:joiner_ids) { [] }

      it "recovers an empty joiner_ids array" do
        expect(parsed[:joiner_ids]).to eq([])
      end
    end

    context "when the note contains a mention-looking substring" do
      let(:message) { "invite <@999> maybe" }
      let(:joiner_ids) { [333] }

      it "does not leak the note's mention into joiner_ids" do
        expect(parsed[:joiner_ids]).to eq([333])
      end

      it "keeps the note verbatim" do
        expect(parsed[:message]).to eq("invite <@999> maybe")
      end
    end

    context "when the message JSON has only one text block" do
      let(:echo) { {"components" => [{"type" => 10, "content" => "hi"}]} }

      it "returns nil" do
        expect(parsed).to be_nil
      end
    end
  end
end
