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
    let(:undo_verdict_button) do
      {custom_id: "mod:undo_verdict:deadbeefdeadbeef", type: Bot::Discord::Components::BUTTON}
    end
    let(:fake_container) do
      double(
        "container",
        components: [text_component, gallery_component, divider_component, button_component],
        buttons: []
      )
    end
    let(:message) { double("message", components: [fake_container]) }

    before do
      allow(event).to receive(:message).and_return(message)
      allow(event).to receive(:update_message)
      allow(button_component).to receive(:respond_to?).with(:content).and_return(false)
      allow(button_component).to receive(:respond_to?).with(:items).and_return(false)
      allow(button_component).to receive(:respond_to?).with(:divider?).and_return(false)
      allow(Moderation::Interaction::VerdictButtons).to receive(:build).and_return([undo_verdict_button])
    end

    it "retains the text and gallery, drops old button rows, appends separator, resolution text, and new action row" do
      handler.send(:resolve, "Confirmed as a scam by <@222>.")

      expect(event).to have_received(:update_message) do |kwargs|
        inner_blocks = kwargs[:components].first[:components]
        types = inner_blocks.map { |b| b[:type] }
        expect(types).to eq([
          Bot::Discord::Components::TEXT_DISPLAY,
          Bot::Discord::Components::MEDIA_GALLERY,
          Bot::Discord::Components::SEPARATOR,
          Bot::Discord::Components::SEPARATOR,
          Bot::Discord::Components::TEXT_DISPLAY,
          Bot::Discord::Components::ACTION_ROW
        ])
        expect(inner_blocks[-2][:content]).to eq("Confirmed as a scam by <@222>.")
        action_row = inner_blocks.last
        expect(action_row[:components].map { |b| b[:custom_id] }).to eq(["mod:undo_verdict:deadbeefdeadbeef"])
      end
    end

    it "calls VerdictButtons.build with the guild config and phash_hex" do
      handler.send(:resolve, "Confirmed as a scam by <@222>.")

      expect(Moderation::Interaction::VerdictButtons).to have_received(:build).with(
        server_configuration: config,
        phash_hex: "deadbeefdeadbeef"
      )
    end

    context "when VerdictButtons.build returns confirm and dismiss buttons" do
      let(:confirm_button) { {custom_id: "mod:confirm:deadbeefdeadbeef", type: Bot::Discord::Components::BUTTON} }
      let(:dismiss_button) { {custom_id: "mod:dismiss:deadbeefdeadbeef", type: Bot::Discord::Components::BUTTON} }

      before do
        allow(Moderation::Interaction::VerdictButtons).to receive(:build).and_return([confirm_button, dismiss_button])
      end

      it "rebuilds the row with confirm and dismiss buttons" do
        handler.send(:resolve, "Verdict undone by <@222>.")

        expect(event).to have_received(:update_message) do |kwargs|
          inner_blocks = kwargs[:components].first[:components]
          action_row = inner_blocks.last
          expect(action_row[:type]).to eq(Bot::Discord::Components::ACTION_ROW)
          custom_ids = action_row[:components].map { |b| b[:custom_id] }
          expect(custom_ids).to eq(["mod:confirm:deadbeefdeadbeef", "mod:dismiss:deadbeefdeadbeef"])
        end
      end
    end

    context "when the message has no root container" do
      let(:message) { double("message", components: []) }

      it "still appends the resolution without raising" do
        handler.send(:resolve, "Done")
        expect(event).to have_received(:update_message).with(hash_including(has_components: true))
      end
    end

    context "when the message already has a mod:undo_punishment: button" do
      let(:punishment_button) do
        double("btn", custom_id: "mod:undo_punishment:222:timeout", label: "Undo punishment", style: 2)
      end
      let(:fake_container) do
        double(
          "container",
          components: [text_component, gallery_component, divider_component, button_component],
          buttons: [punishment_button]
        )
      end

      it "preserves the punishment button alongside the verdict button after a verdict rebuild" do
        handler.send(:resolve, "Confirmed as a scam by <@222>.")

        expect(event).to have_received(:update_message) do |kwargs|
          inner_blocks = kwargs[:components].first[:components]
          action_row = inner_blocks.last
          expect(action_row[:type]).to eq(Bot::Discord::Components::ACTION_ROW)
          custom_ids = action_row[:components].map { |b| b[:custom_id] }
          expect(custom_ids).to include("mod:undo_verdict:deadbeefdeadbeef")
          expect(custom_ids).to include("mod:undo_punishment:222:timeout")
        end
      end
    end

    context "when the message has a button with no custom_id" do
      let(:link_button) { double("btn", custom_id: nil, label: "Open", style: 5) }
      let(:fake_container) do
        double(
          "container",
          components: [text_component, gallery_component, divider_component, button_component],
          buttons: [link_button]
        )
      end

      it "ignores it and preserves no punishment button" do
        handler.send(:resolve, "Confirmed as a scam by <@222>.")

        expect(event).to have_received(:update_message) do |kwargs|
          action_row = kwargs[:components].first[:components].last
          custom_ids = action_row[:components].map { |b| b[:custom_id] }
          expect(custom_ids).to eq(["mod:undo_verdict:deadbeefdeadbeef"])
        end
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
