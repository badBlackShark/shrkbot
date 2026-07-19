# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::PostMessage do
  let(:role_id) { 111 }
  let(:creator_id) { 222 }
  let(:start_ts) { 1_700_000_000 }
  let(:message) { "let's go" }
  let(:joiner_ids) { [333, 444] }
  let(:notify_reply_id) { 555 }
  let(:started) { false }

  describe ".render" do
    subject(:rendered) do
      described_class.render(
        role_id:,
        creator_id:,
        start_ts:,
        message:,
        joiner_ids:,
        notify_reply_id:,
        started:
      )
    end

    let(:container) { rendered[:components].first }
    let(:text_blocks) { container[:components] }
    let(:action_row) { rendered[:components].second }

    it "sets the Components V2 flag" do
      expect(rendered[:flags]).to eq(Bot::Discord::Components::COMPONENTS_V2)
    end

    it "renders exactly three text blocks" do
      expect(text_blocks.size).to eq(3)
      expect(text_blocks).to all(include(type: Bot::Discord::Components::TEXT_DISPLAY))
    end

    it "renders the Join and Done looking buttons with the right custom_ids" do
      buttons = action_row[:components]

      expect(buttons.map { |b| b[:custom_id] }).to eq([
        Lfg::CustomId.join(creator_id, start_ts),
        Lfg::CustomId.done(creator_id, start_ts)
      ])
    end

    context "when the game has not started" do
      let(:started) { false }

      it "uses gathering wording" do
        expect(text_blocks.first[:content]).to include("is looking to play")
        expect(text_blocks.first[:content]).to include("Hit **Join**")
      end
    end

    context "when the game has started" do
      let(:started) { true }

      it "uses started wording" do
        expect(text_blocks.first[:content]).to include("game is on now")
      end
    end

    context "when a message is present" do
      let(:message) { "let's go" }

      it "adds the quoted note to the heading" do
        expect(text_blocks.first[:content]).to include("— “let's go”")
      end
    end

    context "when no message is present" do
      let(:message) { nil }

      it "omits the quoted note from the heading" do
        expect(text_blocks.first[:content]).not_to include("“")
      end
    end

    context "with no joiners" do
      let(:joiner_ids) { [] }

      it "shows the empty-joiners copy" do
        expect(text_blocks.second[:content]).to eq("*No one's in yet.*")
      end
    end

    context "with joiners" do
      let(:joiner_ids) { [333, 444] }

      it "lists the joiner count and mentions" do
        expect(text_blocks.second[:content]).to eq("**In (2):** <@333> <@444>")
      end
    end
  end

  describe ".parse" do
    subject(:parsed) { described_class.parse(echo) }

    context "when round-tripped through a rendered message" do
      let(:message) { "colon: and\nnewline" }
      let(:rendered) do
        described_class.render(
          role_id:,
          creator_id:,
          start_ts:,
          message:,
          joiner_ids:,
          notify_reply_id:,
          started:
        )
      end
      let(:echo) { JSON.parse(rendered.to_json) }

      it "recovers the exact original state" do
        expect(parsed).to eq(
          role_id:,
          creator_id:,
          start_ts:,
          notify_reply_id:,
          message:,
          joiner_ids:
        )
      end
    end

    context "when notify_reply_id is nil and there are no joiners" do
      let(:notify_reply_id) { nil }
      let(:joiner_ids) { [] }
      let(:rendered) do
        described_class.render(
          role_id:,
          creator_id:,
          start_ts:,
          message:,
          joiner_ids:,
          notify_reply_id:,
          started:
        )
      end
      let(:echo) { JSON.parse(rendered.to_json) }

      it "recovers a nil notify_reply_id and an empty joiner_ids array" do
        expect(parsed[:notify_reply_id]).to be_nil
        expect(parsed[:joiner_ids]).to eq([])
      end
    end

    context "when the message JSON has no machine line" do
      let(:echo) { {"components" => [{"type" => 10, "content" => "hi"}]} }

      it "returns nil" do
        expect(parsed).to be_nil
      end
    end
  end
end
