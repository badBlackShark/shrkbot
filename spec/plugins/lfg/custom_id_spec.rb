# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::CustomId do
  let(:creator_id) { 123 }
  let(:start_ts) { 456 }

  describe ".join" do
    subject(:custom_id) { described_class.join(creator_id, start_ts) }

    it { is_expected.to eq("lfg:join:123:456") }
  end

  describe ".done" do
    subject(:custom_id) { described_class.done(creator_id, start_ts) }

    it { is_expected.to eq("lfg:done:123:456") }
  end

  describe ".parse" do
    subject(:parsed) { described_class.parse(custom_id) }

    context "with a join custom_id" do
      let(:custom_id) { described_class.join(creator_id, start_ts) }

      it "round-trips the action, creator_id, and start_ts" do
        expect(parsed).to eq(action: :join, creator_id: 123, start_ts: 456)
      end
    end

    context "with a done custom_id" do
      let(:custom_id) { described_class.done(creator_id, start_ts) }

      it "round-trips the action, creator_id, and start_ts" do
        expect(parsed).to eq(action: :done, creator_id: 123, start_ts: 456)
      end
    end

    context "with any custom_id" do
      let(:custom_id) { described_class.join(creator_id, start_ts) }

      it "coerces creator_id and start_ts to integers" do
        expect(parsed[:creator_id]).to be_a(Integer)
        expect(parsed[:start_ts]).to be_a(Integer)
      end
    end

    context "with a truncated custom_id missing segments" do
      let(:custom_id) { "lfg:join" }

      it "returns nil for the absent creator_id and start_ts" do
        expect(parsed).to eq(action: :join, creator_id: nil, start_ts: nil)
      end
    end

    context "with only the prefix" do
      let(:custom_id) { "lfg" }

      it "returns nil for every absent segment" do
        expect(parsed).to eq(action: nil, creator_id: nil, start_ts: nil)
      end
    end
  end
end
