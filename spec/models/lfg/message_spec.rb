# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Message do
  subject(:message) { build(:lfg_message) }

  it "is valid from the factory" do
    expect(message).to be_valid
  end

  it "belongs to a server configuration" do
    expect(message.server_configuration).to be_present
  end

  describe "channel_id" do
    it "is invalid when nil" do
      message.channel_id = nil
      expect(message).not_to be_valid
    end
  end

  describe "message_id" do
    it "is invalid when nil" do
      message.message_id = nil
      expect(message).not_to be_valid
    end

    it "is invalid when not unique" do
      existing = create(:lfg_message)
      duplicate = build(:lfg_message, message_id: existing.message_id)
      expect(duplicate).not_to be_valid
    end
  end
end
