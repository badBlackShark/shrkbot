# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::PendingRemovals do
  subject(:forget) { store.forget(guild_id: 1, user_id: 7, at:) }

  let(:store) { described_class.new }
  let(:now) { Time.utc(2026, 7, 23, 12, 0, 0) }
  let(:at) { now }

  it "retains for 30 seconds" do
    expect(described_class.retention).to eq(30.seconds)
  end

  context "when a removal is pending" do
    before { store.remember(guild_id: 1, user_id: 7, at: now) }

    it "reports the pending removal" do
      expect(forget).to be(true)
    end

    it "reports it only once" do
      forget

      expect(store.forget(guild_id: 1, user_id: 7, at:)).to be(false)
    end

    context "once the retention window has closed" do
      let(:at) { now + described_class.retention }

      it "has dropped the removal" do
        expect(forget).to be(false)
      end
    end
  end

  context "when no removal is pending" do
    it "reports nothing to do" do
      expect(forget).to be(false)
    end
  end
end
