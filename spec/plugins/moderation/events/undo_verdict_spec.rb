# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::UndoVerdict do
  include_context "moderation button event"

  let(:custom_id) { "mod:undo_verdict:#{phash_hex}" }
  let(:phash_hex) { "deadbeefdeadbeef" }

  let(:confirm_button) { {custom_id: "mod:confirm:#{phash_hex}", type: Bot::Discord::Components::BUTTON} }
  let(:dismiss_button) { {custom_id: "mod:dismiss:#{phash_hex}", type: Bot::Discord::Components::BUTTON} }

  before do
    allow(Ops::Moderation::Phashes::Clear).to receive(:call)
    allow(Moderation::Interaction::VerdictButtons).to receive(:build).and_return([confirm_button, dismiss_button])
  end

  context "when the member holds the staff role" do
    it "clears the phash confirmation" do
      handle

      expect(Ops::Moderation::Phashes::Clear).to have_received(:call).with(server_configuration: config, phash_hex:)
    end

    it "rebuilds the message with the confirm and dismiss buttons from VerdictButtons.build" do
      handle

      expect(event).to have_received(:update_message) do |kwargs|
        inner_blocks = kwargs[:components].first[:components]
        action_row = inner_blocks.find { |b| b[:type] == Bot::Discord::Components::ACTION_ROW }
        custom_ids = action_row[:components].map { |button| button[:custom_id] }
        expect(custom_ids).to eq(["mod:confirm:#{phash_hex}", "mod:dismiss:#{phash_hex}"])
      end
    end
  end

  context "when the member lacks the staff role but has Manage Messages" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: true) }

    it "is authorized and clears the phash" do
      handle
      expect(Ops::Moderation::Phashes::Clear).to have_received(:call).with(server_configuration: config, phash_hex:)
    end
  end

  context "when the member has neither staff role nor Manage Messages" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: false) }

    it "rejects without touching the phash" do
      handle

      expect(Ops::Moderation::Phashes::Clear).not_to have_received(:call)
      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:update_message)
    end
  end
end
