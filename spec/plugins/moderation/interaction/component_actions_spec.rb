# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Interaction::ComponentActions do
  subject(:handler) { includer.new(event) }

  let(:includer) do
    Class.new(Bot::BaseEvent) do
      include Moderation::Interaction::ComponentActions
    end
  end

  let(:guild_id) { 111 }
  let(:user_id) { 222 }
  let(:staff_role_id) { 333 }

  let!(:config) { create(:server_configuration, discord_id: guild_id) }

  let(:server) { double("server", id: guild_id) }
  let(:user) { double("user", id: user_id) }
  let(:roles) { [] }
  let(:manage_messages) { false }
  let(:member) { double("member", roles:, permission?: manage_messages) }
  let(:event) { double("event", server:, user:, custom_id: "mod:confirm:deadbeefdeadbeef") }

  before do
    allow(server).to receive(:member).with(user_id).and_return(member) if server
  end

  describe "#server_configuration" do
    it "loads the guild's config and memoizes it" do
      first = handler.send(:server_configuration)
      expect(first).to eq(config)
      expect(handler.send(:server_configuration)).to be(first)
    end

    context "when the interaction has no server" do
      let(:server) { nil }

      it "is nil" do
        expect(handler.send(:server_configuration)).to be_nil
      end
    end
  end

  describe "#member" do
    it "resolves and memoizes the acting member" do
      expect(handler.send(:member)).to eq(member)
      expect(handler.send(:member)).to eq(member)
    end

    context "when the interaction has no server" do
      let(:server) { nil }

      it "is nil" do
        expect(handler.send(:member)).to be_nil
      end
    end
  end

  describe "#resolve" do
    let(:text_component) { Struct.new(:content).new("**Scam flagged**\nSome body.\n-# meta") }
    let(:media_item) { Struct.new(:media).new(Struct.new(:url).new("https://cdn/x.png")) }
    let(:gallery_component) { Struct.new(:items).new([media_item]) }
    let(:divider_component) { double("divider", divider?: true) }
    let(:button_component) { double("button") }
    let(:fake_container) do
      double(
        "container",
        components: [text_component, gallery_component, divider_component, button_component]
      )
    end
    let(:message) { double("message", components: [fake_container]) }

    before do
      allow(event).to receive(:message).and_return(message)
      allow(event).to receive(:update_message)
      allow(button_component).to receive(:respond_to?).with(:content).and_return(false)
      allow(button_component).to receive(:respond_to?).with(:items).and_return(false)
      allow(button_component).to receive(:respond_to?).with(:divider?).and_return(false)
    end

    it "retains the text and gallery, drops button rows, appends separator and resolution text" do
      handler.send(:resolve, "Confirmed as a scam by <@222>.")

      expect(event).to have_received(:update_message) do |kwargs|
        inner_blocks = kwargs[:components].first[:components]
        types = inner_blocks.map { |b| b[:type] }
        expect(types).to eq([
          Bot::Discord::Components::TEXT_DISPLAY,
          Bot::Discord::Components::MEDIA_GALLERY,
          Bot::Discord::Components::SEPARATOR,
          Bot::Discord::Components::SEPARATOR,
          Bot::Discord::Components::TEXT_DISPLAY
        ])
        expect(inner_blocks.last[:content]).to eq("Confirmed as a scam by <@222>.")
      end
    end

    context "when the message has no root container" do
      let(:message) { double("message", components: []) }

      it "still appends the resolution without raising" do
        handler.send(:resolve, "Done")
        expect(event).to have_received(:update_message).with(hash_including(has_components: true))
      end
    end
  end

  describe "#authorized?" do
    context "when the member cannot be resolved" do
      before { allow(server).to receive(:member).with(user_id).and_return(nil) }

      it "is false" do
        expect(handler.send(:authorized?)).to be(false)
      end
    end

    context "when the member holds the configured staff role" do
      let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }
      let(:roles) { [double("role", id: staff_role_id)] }

      it "is true" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when no staff role is configured but the member has Manage Messages" do
      let(:manage_messages) { true }

      it "is true" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when the guild has no stored configuration" do
      let(:server) { double("server", id: 999) }
      let(:manage_messages) { true }

      it "falls back to the Manage Messages permission" do
        expect(handler.send(:authorized?)).to be(true)
      end
    end

    context "when the staff role is configured but the member lacks it and Manage Messages" do
      let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }

      it "is false" do
        expect(handler.send(:authorized?)).to be(false)
      end
    end
  end
end
