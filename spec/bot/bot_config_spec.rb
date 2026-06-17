require "rails_helper"

RSpec.describe BotConfig do
  describe ".rest_token" do
    subject(:rest_token) { described_class.rest_token }

    before { allow(described_class).to receive(:token).and_return(token) }

    context "with a raw token" do
      let(:token) { "abc123" }

      it "prefixes with 'Bot ' for the REST API" do
        expect(rest_token).to eq("Bot abc123")
      end
    end

    context "with an already-prefixed token" do
      let(:token) { "Bot abc123" }

      it "doesn't double-prefix" do
        expect(rest_token).to eq("Bot abc123")
      end
    end
  end
end
