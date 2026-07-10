# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discord::Components do
  describe ".action_row" do
    subject(:row) { described_class.action_row([button]) }

    let(:button) { described_class.button(custom_id: "mod:confirm:abc", label: "Confirm scam") }

    it "wraps the components in an action row block" do
      expect(row).to eq(type: described_class::ACTION_ROW, components: [button])
    end
  end

  describe ".send_to" do
    let(:rendered) { described_class.container([described_class.text("hello")]) }
    let(:channel) { double("channel", send_message: nil) }

    it "passes nil for attachments when none given" do
      expect(channel).to receive(:send_message) do |_content, _tts, _embed, attachments, *_rest|
        expect(attachments).to be_nil
      end
      described_class.send_to(channel, rendered)
    end

    it "forwards attachments when given" do
      io = Discord::FileUpload.new("bytes", "img.png")
      expect(channel).to receive(:send_message) do |_content, _tts, _embed, attachments, *_rest|
        expect(attachments).to eq([io])
      end
      described_class.send_to(channel, rendered, attachments: [io])
    end
  end

  describe ".button" do
    subject(:button) do
      described_class.button(
        custom_id: "mod:dismiss:abc",
        label: "Dismiss",
        style: described_class::BUTTON_DANGER
      )
    end

    it "builds a button block carrying the style, label, and custom_id" do
      expect(button).to eq(
        type: described_class::BUTTON,
        style: described_class::BUTTON_DANGER,
        label: "Dismiss",
        custom_id: "mod:dismiss:abc"
      )
    end

    context "without an explicit style" do
      subject(:button) { described_class.button(custom_id: "mod:confirm:abc", label: "Confirm scam") }

      it "defaults to the primary style" do
        expect(button[:style]).to eq(1)
      end
    end
  end

  describe ".section" do
    subject(:section) { described_class.section([text], accessory: thumbnail) }

    let(:text) { described_class.text("hello") }
    let(:thumbnail) { described_class.thumbnail("https://example.test/icon.png") }

    it "wraps the blocks in a section carrying the accessory" do
      expect(section).to eq(
        type: described_class::SECTION,
        components: [text],
        accessory: thumbnail
      )
    end
  end

  describe ".thumbnail" do
    subject(:thumbnail) { described_class.thumbnail("https://example.test/icon.png") }

    it "builds a thumbnail block pointing at the url" do
      expect(thumbnail).to eq(
        type: described_class::THUMBNAIL,
        media: {url: "https://example.test/icon.png"}
      )
    end
  end
end
