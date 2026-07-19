# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Bot::Discord::Components do
  describe ".action_row" do
    subject(:row) { described_class.action_row([button]) }

    let(:button) { described_class.button(custom_id: "mod:confirm:abc", label: "Confirm scam") }

    it "wraps the components in an action row block" do
      expect(row).to eq(type: described_class::ACTION_ROW, components: [button])
    end
  end

  describe ".create_message" do
    subject(:create_message) { described_class.create_message(channel_id: 20, content: "hello", allowed_mentions:, reply_to_id:) }

    let(:allowed_mentions) { {parse: [], users: [1]} }
    let(:reply_to_id) { nil }

    before do
      allow(Bot::Config).to receive(:token).and_return("tok")
      allow(Discordrb::API::Channel).to receive(:create_message).and_return({id: 7}.to_json)
    end

    it "returns the created message's id" do
      expect(create_message).to eq(7)
    end

    it "passes content and allowed_mentions through" do
      expect(Discordrb::API::Channel).to receive(:create_message) do |_token, channel_id, content, _tts, _embeds, _nonce, _attachments, mentions, _message_reference, _components, _flags|
        expect(channel_id).to eq(20)
        expect(content).to eq("hello")
        expect(mentions).to eq(allowed_mentions)
        {id: 7}.to_json
      end
      create_message
    end

    it "omits the message_reference when reply_to_id is not given" do
      expect(Discordrb::API::Channel).to receive(:create_message) do |*args|
        expect(args[8]).to be_nil
        {id: 7}.to_json
      end
      create_message
    end

    context "with a reply_to_id" do
      let(:reply_to_id) { 500 }

      it "sets message_reference to the replied-to message id" do
        expect(Discordrb::API::Channel).to receive(:create_message) do |*args|
          expect(args[8]).to eq({message_id: 500})
          {id: 7}.to_json
        end
        create_message
      end
    end
  end

  describe ".send_to" do
    subject(:send_to) { described_class.send_to(channel, rendered, attachments:) }

    let(:rendered) { described_class.container([described_class.text("hello")]) }
    let(:channel) { double("channel", send_message: nil) }
    let(:attachments) { nil }

    it "passes nil for attachments when none given" do
      expect(channel).to receive(:send_message) do |_content, _tts, _embed, sent_attachments, *_rest|
        expect(sent_attachments).to be_nil
      end
      send_to
    end

    it "does not edit the message when no subject is given" do
      expect(Discordrb::API::Channel).not_to receive(:edit_message)
      send_to
    end

    context "with attachments" do
      let(:attachments) { [Bot::Discord::FileUpload.new("bytes", "img.png")] }

      it "forwards them" do
        expect(channel).to receive(:send_message) do |_content, _tts, _embed, sent_attachments, *_rest|
          expect(sent_attachments).to eq(attachments)
        end
        send_to
      end
    end

    context "with a subject" do
      subject(:send_to) { described_class.send_to(channel, rendered, subject: "reminder: hello") }

      let(:message) { double("message", id: 30) }
      let(:channel) { double("channel", id: 20, send_message: message) }

      before do
        allow(Bot::Config).to receive(:rest_token).and_return("Bot tok")
        allow(Discordrb::API::Channel).to receive(:edit_message)
      end

      it "sends the subject as a plain message so the push notification has a preview" do
        expect(channel).to receive(:send_message).with(
          "reminder: hello",
          false,
          nil,
          nil,
          nil,
          nil,
          nil,
          0
        ).and_return(message)
        send_to
      end

      it "converts the message to components v2 with the content nulled out and mention re-parsing suppressed" do
        expect(Discordrb::API::Channel).to receive(:edit_message).with(
          "Bot tok",
          20,
          30,
          nil,
          {parse: []},
          nil,
          rendered[:components],
          rendered[:flags]
        )
        send_to
      end

      it "returns the sent message" do
        expect(send_to).to eq(message)
      end

      context "when the conversion fails" do
        before do
          allow(Discordrb::API::Channel).to receive(:edit_message).and_raise("500 oops")
        end

        it "leaves the plain message standing and returns it" do
          expect(send_to).to eq(message)
        end
      end
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
        expect(button[:style]).to eq(described_class::BUTTON_PRIMARY)
      end
    end
  end

  describe ".link_button" do
    subject(:link_button) { described_class.link_button(url: "https://example.test", label: "Example") }

    it "builds a link-style button carrying the url and label" do
      expect(link_button).to eq(
        type: described_class::BUTTON,
        style: described_class::BUTTON_LINK,
        url: "https://example.test",
        label: "Example"
      )
    end
  end

  describe ".container" do
    subject(:container) { described_class.container([described_class.text("hello")]) }

    it "wraps the blocks in a single accented container" do
      expect(container[:components].sole).to include(type: described_class::CONTAINER)
    end

    context "with buttons" do
      subject(:container) { described_class.container([described_class.text("hello")], buttons: [button]) }

      let(:button) { described_class.link_button(url: "https://example.test", label: "Example") }

      it "appends an action row after the container" do
        expect(container[:components].last).to eq(
          type: described_class::ACTION_ROW,
          components: [button]
        )
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
