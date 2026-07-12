# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Unpunisher do
  let(:user_id) { 222 }
  let(:member) { double("member") }
  let(:server) { double("server") }

  subject(:result) { described_class.call(server:, user_id:, punishment:) }

  context "when punishment is 'timeout' and the member is in the server" do
    let(:punishment) { "timeout" }

    before do
      allow(server).to receive(:member).with(user_id).and_return(member)
      allow(member).to receive(:communication_disabled_until=)
    end

    it "clears the timeout" do
      result
      expect(member).to have_received(:communication_disabled_until=).with(nil)
    end

    it "returns :reversed" do
      expect(result).to eq(:reversed)
    end
  end

  context "when punishment is 'timeout' and the member is not in the server" do
    let(:punishment) { "timeout" }

    before { allow(server).to receive(:member).with(user_id).and_return(nil) }

    it "returns :not_in_server" do
      expect(result).to eq(:not_in_server)
    end
  end

  context "when punishment is 'ban'" do
    let(:punishment) { "ban" }

    before { allow(server).to receive(:unban) }

    it "unbans the user" do
      result
      expect(server).to have_received(:unban).with(user_id)
    end

    it "returns :reversed" do
      expect(result).to eq(:reversed)
    end
  end

  context "when punishment is 'kick'" do
    let(:punishment) { "kick" }

    it "returns :noop" do
      expect(result).to eq(:noop)
    end
  end

  context "when punishment is 'none'" do
    let(:punishment) { "none" }

    it "returns :noop" do
      expect(result).to eq(:noop)
    end
  end

  context "when the discordrb call raises" do
    let(:punishment) { "ban" }

    before do
      allow(server).to receive(:unban).and_raise(RuntimeError, "forbidden")
      allow(Rails.logger).to receive(:warn)
    end

    it "returns :failed" do
      expect(result).to eq(:failed)
    end

    it "logs the failure" do
      result
      expect(Rails.logger).to have_received(:warn).with(
        "[Moderation::Unpunisher] ban reversal failed: RuntimeError: forbidden"
      )
    end
  end
end
