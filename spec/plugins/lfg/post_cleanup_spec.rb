# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::PostCleanup do
  subject(:close) { described_class.close(record, 500) { |id| deleted << id } }

  let(:deleted) { [] }

  context "with a record carrying follow-up ids" do
    let(:record) { create(:lfg_message, message_id: 500, notify_reply_id: 600, start_ping_id: 700) }

    it "deletes the follow-ups and the post, then destroys the record" do
      expect(Ops::Lfg::Message::Destroy).to receive(:call).with(message: record)
      close
      expect(deleted).to contain_exactly(600, 700, 500)
    end
  end

  context "with a record that has no follow-ups" do
    let(:record) { create(:lfg_message, message_id: 500, notify_reply_id: nil, start_ping_id: nil) }

    it "deletes only the post and destroys the record" do
      expect(Ops::Lfg::Message::Destroy).to receive(:call).with(message: record)
      close
      expect(deleted).to eq([500])
    end
  end

  context "without a record" do
    let(:record) { nil }

    it "deletes only the post and destroys nothing" do
      expect(Ops::Lfg::Message::Destroy).not_to receive(:call)
      close
      expect(deleted).to eq([500])
    end
  end
end
