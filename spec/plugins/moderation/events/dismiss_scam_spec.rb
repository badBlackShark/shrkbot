# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::DismissScam do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:staff_role_id) { 333 }
  let(:phash_hex) { "deadbeefdeadbeef" }

  let!(:config) { create(:server_configuration, discord_id: guild_id) }
  let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }

  let(:staff_role) { double("role", id: staff_role_id) }
  let(:member) { double("member", mention: "<@222>", roles: [staff_role], permission?: false) }
  let(:server) { double("server", id: guild_id) }
  let(:user) { double("user", id: 222) }
  let(:event) do
    double(
      "event",
      custom_id: "mod:dismiss:#{phash_hex}",
      server:,
      user:,
      update_message: nil,
      respond: nil,
      bot: double("bot")
    )
  end

  before do
    allow(server).to receive(:member).with(222).and_return(member)
    allow(Ops::Moderation::Phashes::Dismiss).to receive(:call)
  end

  context "when the member is authorized" do
    it "prompts for confirmation with a dismiss_confirm button and does not write" do
      handle

      expect(Ops::Moderation::Phashes::Dismiss).not_to have_received(:call)
      expect(event).to have_received(:respond) do |args|
        expect(args[:ephemeral]).to be(true)
        expect(args[:has_components]).to be(true)
        button = args[:components].dig(0, :components, 1, :components, 0)
        expect(button[:custom_id]).to eq("mod:dismiss_confirm:#{phash_hex}")
      end
    end
  end

  context "when the member is unauthorized" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: false) }

    it "rejects" do
      handle

      expect(Ops::Moderation::Phashes::Dismiss).not_to have_received(:call)
      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
    end
  end
end
