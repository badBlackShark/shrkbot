require "rails_helper"

RSpec.describe Commands::Donate do
  subject(:execute) { described_class.new(event).execute }

  let(:event) { double("event", respond: nil) }

  it "responds with the donation message, ephemerally" do
    expect(event).to receive(:respond).with(hash_including(content: described_class::MESSAGE, ephemeral: true))
    execute
  end

  describe "the message content" do
    subject(:message) { described_class::MESSAGE }

    it { is_expected.to include("https://paypal.me/trueblackshark") }
    it { is_expected.to include("https://liberapay.com/badBlackShark") }
    it { is_expected.to include("10.60€") }
    it { is_expected.not_to match(/yahoo/i) }
  end
end
