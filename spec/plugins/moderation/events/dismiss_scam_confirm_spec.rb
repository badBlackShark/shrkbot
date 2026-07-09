# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::DismissScamConfirm do
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
  let(:fake_container) { double("container", components: []) }
  let(:fake_message) { double("message", components: [fake_container]) }
  let(:event) do
    double(
      "event",
      custom_id: "mod:dismiss_confirm:#{phash_hex}",
      server:,
      user:,
      update_message: nil,
      respond: nil,
      bot: double("bot"),
      message: fake_message
    )
  end

  before do
    allow(server).to receive(:member).with(222).and_return(member)
    allow(Ops::Moderation::Phashes::Dismiss).to receive(:call)
  end

  context "when the member is authorized" do
    it "dismisses the phash and resolves the flag post" do
      handle

      expect(Ops::Moderation::Phashes::Dismiss).to have_received(:call).with(server_configuration: config, phash_hex:)
      expect(event).to have_received(:update_message).with(hash_including(has_components: true))
    end
  end

  context "when the member is unauthorized" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: false) }

    it "rejects without touching the phash" do
      handle

      expect(Ops::Moderation::Phashes::Dismiss).not_to have_received(:call)
      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:update_message)
    end
  end
end
