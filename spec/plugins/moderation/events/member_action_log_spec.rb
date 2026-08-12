# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberActionLog do
  subject(:handle) { klass.new(event).handle }

  let(:klass) do
    Class.new(described_class) do
      event_key :member_banned
    end
  end

  include_context "audit log entry event"

  let(:built_entry) { {title: "t", body: "b", meta: "m"} }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(server_configuration)
    allow(Bot::ActivityLog).to receive(:enabled?).and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
    allow(Moderation::MemberLog::ActivityEntry).to receive(:build).and_return(built_entry)
  end

  it "posts the built entry" do
    handle
    expect(Bot::ActivityLog).to have_received(:post).with(
      server_configuration,
      bot:,
      allowed_mentions: {parse: [], users: [target.id]},
      **built_entry
    )
  end

  it "passes the audit entry's moderator, reason and target to ActivityEntry.build" do
    handle
    expect(Moderation::MemberLog::ActivityEntry).to have_received(:build).with(
      event_key: :member_banned,
      target:,
      moderator:,
      reason:
    )
  end

  context "when no ServerConfiguration exists for the guild" do
    before { allow(ServerConfiguration).to receive(:find_by).and_return(nil) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the toggle is disabled" do
    before { allow(Bot::ActivityLog).to receive(:enabled?).and_return(false) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the event has no server" do
    let(:event) { double("event", server: nil, bot:, entry: audit_entry, user_id: moderator_id) }

    before do
      allow(ServerConfiguration).to receive(:find_by).with(discord_id: nil).and_return(nil)
    end

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when shrkbot performed the action" do
    let(:moderator_id) { bot_user_id }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the audit entry has no target" do
    let(:target) { nil }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end
end
