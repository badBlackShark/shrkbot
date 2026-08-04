# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberKickLog do
  subject(:handle) { described_class.new(event).handle }

  include_context "audit log entry event"

  let(:reason) { "rule break" }
  let(:built_entry) { {title: "Member kicked", body: "body", meta: "meta"} }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(server_configuration)
    allow(Bot::ActivityLog).to receive(:enabled?).with(server_configuration, "moderation.member_kicked").and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
    allow(Moderation::MemberLog::ActivityEntry).to receive(:build).and_return(built_entry)
  end

  it "registers on the kick audit action" do
    expect(described_class.discord_events).to eq([:audit_log_entry])
    expect(described_class.event_attributes).to eq(action: :member_kick)
  end

  it "posts when the toggle is enabled" do
    handle
    expect(Bot::ActivityLog).to have_received(:post)
  end

  context "when shrkbot performed the kick" do
    let(:moderator_id) { bot_user_id }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end
end
