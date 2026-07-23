# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::PendingJoins do
  subject(:forget) { store.forget(guild_id: 1, user_id: 7, at:) }

  let(:store) { described_class.new }
  let(:now) { Time.utc(2026, 7, 23, 12, 0, 0) }
  let(:at) { now }

  context "when the join is pending" do
    before { store.remember(guild_id: 1, user_id: 7, at: now) }

    it "reports the pending join" do
      expect(forget).to be(true)
    end

    it "reports it only once" do
      forget

      expect(store.forget(guild_id: 1, user_id: 7, at:)).to be(false)
    end

    context "just before the retention window closes" do
      let(:at) { now + described_class::RETENTION - 1.second }

      it "still reports the pending join" do
        expect(forget).to be(true)
      end
    end

    context "once the retention window has closed" do
      let(:at) { now + described_class::RETENTION }

      it "has dropped the join" do
        expect(forget).to be(false)
      end
    end

    context "when the same user is pending on another server" do
      subject(:forget) { store.forget(guild_id: 2, user_id: 7, at:) }

      it "leaves the other server's join alone" do
        expect(forget).to be(false)
      end
    end
  end

  context "when no join is pending" do
    it "reports nothing to do" do
      expect(forget).to be(false)
    end
  end
end
