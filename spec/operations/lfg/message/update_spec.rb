# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Lfg::Message::Update do
  subject(:result) do
    described_class.call(
      message:,
      notify_reply_id:,
      start_ping_id:
    )
  end

  let(:message) { create(:lfg_message) }
  let(:notify_reply_id) { nil }
  let(:start_ping_id) { nil }

  it "succeeds" do
    expect(result).to be_success
  end

  context "when notify_reply_id is given" do
    let(:notify_reply_id) { 999 }

    it "sets notify_reply_id" do
      result

      expect(message.reload.notify_reply_id).to eq(999)
    end

    it "leaves start_ping_id untouched" do
      result

      expect(message.reload.start_ping_id).to be_nil
    end
  end

  context "when start_ping_id is given" do
    let(:start_ping_id) { 888 }

    it "sets start_ping_id" do
      result

      expect(message.reload.start_ping_id).to eq(888)
    end

    it "leaves notify_reply_id untouched" do
      result

      expect(message.reload.notify_reply_id).to be_nil
    end
  end

  context "when neither is given" do
    let(:message) { create(:lfg_message, notify_reply_id: 111, start_ping_id: 222) }

    it "is a no-op save" do
      result

      message.reload
      expect(message.notify_reply_id).to eq(111)
      expect(message.start_ping_id).to eq(222)
    end
  end
end
