# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::MemberKicked do
  subject(:handle) { described_class.new(event).handle }

  include_context "audit log entry event"

  let(:ledger) { Welcomes::PendingRemovals.new }

  before do
    allow(Welcomes::PendingRemovals).to receive(:instance).and_return(ledger)
  end

  it "registers on the kick audit action" do
    expect(described_class.discord_events).to eq([:audit_log_entry])
    expect(described_class.event_attributes).to eq(action: :member_kick)
  end

  it "records the target in the ledger" do
    handle

    expect(ledger.forget(guild_id:, user_id: target.id)).to be(true)
  end

  context "when the entry has no target" do
    let(:target) { nil }

    it "records nothing" do
      handle

      expect(ledger.forget(guild_id:, user_id: 222)).to be(false)
    end
  end
end
