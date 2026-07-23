# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Lfg::Message::Post do
  subject(:result) do
    described_class.call(
      server_configuration: config,
      channel_id:,
      message_id:
    )
  end

  let(:config) { create(:server_configuration) }
  let(:channel_id) { 111 }
  let(:message_id) { 222 }

  it "succeeds" do
    expect(result).to be_success
  end

  it "creates a row with the given ids" do
    result

    record = Lfg::Message.find_by(message_id:)
    expect(record).to be_present
    expect(record.channel_id).to eq(channel_id)
    expect(record.server_configuration).to eq(config)
  end

  it "returns the created record as the value" do
    expect(result.value).to eq(Lfg::Message.find_by(message_id:))
  end
end
