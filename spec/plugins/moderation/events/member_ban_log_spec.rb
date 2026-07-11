# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberBanLog do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:user_id) { 222 }

  let(:user) { double("user", id: user_id) }
  let(:server) { double("server", id: guild_id) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, user:, bot:) }

  let(:server_configuration) { double("server_configuration") }
  let(:attribution) { double("attribution", moderator: double("mod"), reason: "spamming") }
  let(:built_entry) { {title: "Member banned", body: "body", meta: "meta"} }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(server_configuration)
    allow(Bot::ActivityLog).to receive(:enabled?).with(server_configuration, "moderation.member_banned").and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
    allow(Moderation::MemberLog::AuditLogLookup).to receive(:attribution).and_return(attribution)
    allow(Moderation::MemberLog::ActivityEntry).to receive(:build).and_return(built_entry)
  end

  context "when no ServerConfiguration exists" do
    before { allow(ServerConfiguration).to receive(:find_by).and_return(nil) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when action is disabled" do
    before { allow(Bot::ActivityLog).to receive(:enabled?).and_return(false) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end

    it "does not call AuditLogLookup" do
      handle
      expect(Moderation::MemberLog::AuditLogLookup).not_to have_received(:attribution)
    end
  end

  context "when attribution is present" do
    it "posts the built entry" do
      handle
      expect(Bot::ActivityLog).to have_received(:post).with(
        server_configuration,
        bot:,
        **built_entry
      )
    end
  end

  context "when attribution is nil" do
    before { allow(Moderation::MemberLog::AuditLogLookup).to receive(:attribution).and_return(nil) }

    it "still posts with nil moderator and reason" do
      allow(Moderation::MemberLog::ActivityEntry).to receive(:build).with(
        :member_banned,
        target: user,
        moderator: nil,
        reason: nil
      ).and_return(built_entry)

      handle

      expect(Bot::ActivityLog).to have_received(:post)
    end
  end
end
