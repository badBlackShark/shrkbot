# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Roles::Messages::Remove do
  subject(:result) { described_class.call(bot:, role_set: set) }

  let(:bot) { double("bot") }

  before do
    allow(Ops::Roles::Messages::Delete).to receive(:call)
      .and_return(instance_double(Ops::ApplicationOperation::Result, success?: true))
  end

  context "when the set has a message_id" do
    let(:setting) { create(:role_setting, channel_id: 111) }
    let(:set) { create(:role_set, role_setting: setting, message_id: 999, channel_override: nil) }

    it "delegates to Delete with the set's channel and message" do
      result
      expect(Ops::Roles::Messages::Delete).to have_received(:call).with(
        bot:,
        channel_id: 111,
        message_id: 999
      )
    end

    it "clears message_id on the set" do
      result
      expect(set.reload.message_id).to be_nil
    end

    it "returns a success result carrying the set" do
      expect(result).to be_success
      expect(result.value).to eq(set)
    end
  end

  context "when message_id is already nil" do
    let(:set) { create(:role_set, message_id: nil) }

    it "does not call Delete" do
      result
      expect(Ops::Roles::Messages::Delete).not_to have_received(:call)
    end

    it "returns ok" do
      expect(result).to be_success
    end
  end
end
