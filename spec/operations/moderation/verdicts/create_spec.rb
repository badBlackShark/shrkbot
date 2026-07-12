# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Moderation::Verdicts::Create do
  subject(:result) do
    described_class.call(
      server_configuration:,
      discord_user_id: 111_222_333_444,
      action: "flag_for_review",
      punishment: "none",
      phash: "abc123",
      log_channel_id: 555,
      log_message_id: 666
    )
  end

  let(:server_configuration) { create(:server_configuration) }

  it "creates a verdict record" do
    expect { result }.to change(Moderation::VerdictRecord, :count).by(1)
  end

  it "returns success" do
    expect(result).to be_success
  end

  it "returns the created record as the value" do
    expect(result.value).to be_a(Moderation::VerdictRecord)
  end

  it "sets the correct attributes on the record" do
    record = result.value
    expect(record.server_configuration).to eq(server_configuration)
    expect(record.discord_user_id).to eq(111_222_333_444)
    expect(record.action).to eq("flag_for_review")
    expect(record.punishment).to eq("none")
    expect(record.phash).to eq("abc123")
    expect(record.log_channel_id).to eq(555)
    expect(record.log_message_id).to eq(666)
  end

  context "when log ids are omitted" do
    subject(:result) do
      described_class.call(
        server_configuration:,
        discord_user_id: 111_222_333_444,
        action: "flag_for_review",
        punishment: "none",
        phash: "abc123"
      )
    end

    it "creates a record with nil log ids" do
      record = result.value
      expect(record.log_channel_id).to be_nil
      expect(record.log_message_id).to be_nil
    end
  end
end
