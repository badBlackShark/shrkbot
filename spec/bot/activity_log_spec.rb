# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ActivityLog do
  let(:server_config) { create(:server_configuration) }
  let(:channel) { double("channel", send_message: nil) }
  let(:bot) { double("bot") }

  before do
    create(
      :logging_setting,
      server_configuration: server_config,
      channel_id: 555,
      enabled_actions: {"roles.role_gained" => true}
    )
    logging = create(:plugin, key: "logging", name: "Logging")
    create(:plugin_activation, server_configuration: server_config, plugin: logging, enabled: true)
    allow(bot).to receive(:channel).with(555).and_return(channel)
  end

  describe ".post" do
    subject(:post) do
      described_class.post(
        server_config,
        bot:,
        title: "Roles updated",
        body: "<@42> gained **Gamer**.",
        meta: 'Self-assigned via the "Pronouns" role menu'
      )
    end

    it "writes a branded container with title, body, and muted meta line" do
      expect(channel).to receive(:send_message) do |*args|
        expect(args[7]).to eq(Bot::Discord::Components::COMPONENTS_V2)
        content = args[6].first[:components].first[:content]
        expect(content).to eq(
          "**Roles updated**\n<@42> gained **Gamer**.\n-# Self-assigned via the \"Pronouns\" role menu"
        )
      end
      post
    end

    it "suppresses mention pings in the log channel" do
      expect(channel).to receive(:send_message) do |*args|
        expect(args[4]).to eq({parse: []})
      end
      post
    end

    it "sends without a subject by default" do
      expect(Bot::Discord::Components).to receive(:send_to).with(channel, anything, hash_including(subject: nil))
      post
    end

    context "with a subject" do
      subject(:post) do
        described_class.post(
          server_config,
          bot:,
          title: "Scam image removed",
          body: "<@42> posted an image.",
          meta: "The message was deleted automatically.",
          subject: "<@&9>: Scam image removed"
        )
      end

      it "passes it through to the send" do
        expect(Bot::Discord::Components).to receive(:send_to).with(channel, anything, hash_including(subject: "<@&9>: Scam image removed"))
        post
      end
    end

    context "with an image" do
      let(:upload) { Bot::Discord::FileUpload.new("fakebytes", "scam.png") }

      subject(:post) do
        described_class.post(
          server_config,
          bot:,
          title: "Scam image removed",
          body: "<@42> posted an image.",
          meta: "The message was deleted automatically.",
          image: upload
        )
      end

      it "appends a media gallery block referencing the attachment filename" do
        expect(channel).to receive(:send_message) do |*args|
          blocks = args[6].first[:components]
          gallery = blocks.find { |block| block[:type] == Bot::Discord::Components::MEDIA_GALLERY }
          expect(gallery[:items]).to eq([{media: {url: "attachment://scam.png"}}])
        end
        post
      end

      it "passes the FileUpload as an attachment" do
        expect(channel).to receive(:send_message) do |*args|
          expect(args[3]).to eq([upload])
        end
        post
      end
    end

    context "with extra components" do
      let(:upload) { Bot::Discord::FileUpload.new("fakebytes", "scam.png") }
      let(:action_row) do
        Bot::Discord::Components.action_row(
          [Bot::Discord::Components.button(custom_id: "mod:confirm:abc", label: "Confirm scam")]
        )
      end

      subject(:post) do
        described_class.post(
          server_config,
          bot:,
          title: "Scam image removed",
          body: "<@42> posted an image.",
          meta: "The message was deleted automatically.",
          image: upload,
          components: [action_row]
        )
      end

      it "appends the components after the text and media blocks" do
        expect(channel).to receive(:send_message) do |*args|
          blocks = args[6].first[:components]
          expect(blocks.last).to eq(action_row)
          expect(blocks.index(action_row)).to be > blocks.index { |block| block[:type] == Bot::Discord::Components::MEDIA_GALLERY }
        end
        post
      end
    end

    context "when no logging channel is set" do
      before do
        server_config.logging_setting.update!(channel_id: nil)
      end

      it "writes nothing" do
        expect(channel).not_to receive(:send_message)
        post
      end
    end

    context "when the logging channel no longer exists" do
      before do
        allow(bot).to receive(:channel).with(555).and_return(nil)
      end

      it "writes nothing and doesn't raise" do
        expect { post }.not_to raise_error
      end
    end

    context "when the channel send fails" do
      before do
        allow(channel).to receive(:send_message).and_raise("403 missing access")
      end

      it "swallows the error so the user's action is unaffected" do
        expect { post }.not_to raise_error
      end
    end
  end

  describe ".enabled?" do
    subject(:enabled) { described_class.enabled?(server_config, action) }

    let(:action) { "roles.role_gained" }

    it "is true when the plugin is on and the action is toggled on" do
      expect(enabled).to be(true)
    end

    context "when the logging plugin is disabled" do
      before do
        PluginActivation.update_all(enabled: false)
      end

      it "is false" do
        expect(enabled).to be(false)
      end
    end

    context "when the action's toggle is off" do
      let(:action) { "roles.role_lost" }

      it "is false" do
        expect(enabled).to be(false)
      end
    end
  end
end
