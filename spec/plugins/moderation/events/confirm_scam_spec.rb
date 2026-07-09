# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ConfirmScam do
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
      custom_id: "mod:confirm:#{phash_hex}",
      server:,
      user:,
      update_message: nil,
      respond: nil,
      bot: double("bot")
    )
  end

  before do
    allow(server).to receive(:member).with(222).and_return(member)
    allow(Ops::Moderation::Phashes::Confirm).to receive(:call)
  end

  context "when the member holds the staff role" do
    it "confirms the phash and resolves the flag post" do
      handle

      expect(Ops::Moderation::Phashes::Confirm).to have_received(:call).with(server_configuration: config, phash_hex:)
      expect(event).to have_received(:update_message).with(hash_including(has_components: true))
    end
  end

  context "when the member lacks the staff role but has Manage Messages" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: true) }

    it "is authorized and confirms the phash" do
      handle
      expect(Ops::Moderation::Phashes::Confirm).to have_received(:call).with(server_configuration: config, phash_hex:)
    end
  end

  context "when the member has neither staff role nor Manage Messages" do
    let(:member) { double("member", mention: "<@222>", roles: [], permission?: false) }

    it "rejects without touching the phash" do
      handle

      expect(Ops::Moderation::Phashes::Confirm).not_to have_received(:call)
      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:update_message)
    end
  end
end
