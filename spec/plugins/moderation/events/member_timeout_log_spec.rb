# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberTimeoutLog do
  subject(:handle) { described_class.new(event).handle }

  include_context "audit log entry event"

  let(:reason) { "misbehaving" }
  let(:new_expiry) { "2026-07-11T00:00:00+00:00" }
  let(:changes) { {"communication_disabled_until" => double("change", new: new_expiry)} }
  let(:built_entry) { {title: "Member timed out", body: "body", meta: "meta"} }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(server_configuration)
    allow(Bot::ActivityLog).to receive(:enabled?).with(server_configuration, "moderation.member_timed_out").and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
    allow(Moderation::MemberLog::ActivityEntry).to receive(:build).and_return(built_entry)
  end

  it "registers on the member_update audit action" do
    expect(described_class.discord_events).to eq([:audit_log_entry])
    expect(described_class.event_attributes).to eq(action: :member_update)
  end

  it "posts and passes the parsed timeout_until to ActivityEntry.build" do
    handle
    expect(Moderation::MemberLog::ActivityEntry).to have_received(:build).with(
      event_key: :member_timed_out,
      target:,
      moderator:,
      reason:,
      timeout_until: Time.zone.parse(new_expiry)
    )
    expect(Bot::ActivityLog).to have_received(:post)
  end

  context "when the timeout was removed" do
    let(:new_expiry) { nil }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the audit entry is an unrelated member_update, e.g. a nickname change" do
    let(:changes) { {"nick" => double("change", new: "bob")} }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the audit entry has no changes" do
    let(:changes) { {} }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when shrkbot performed the timeout" do
    let(:moderator_id) { bot_user_id }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end
end
