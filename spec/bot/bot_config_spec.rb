require "rails_helper"

RSpec.describe BotConfig do
  describe ".rest_token" do
    it "prefixes the raw token with 'Bot ' for the REST API" do
      allow(described_class).to receive(:token).and_return("abc123")
      expect(described_class.rest_token).to eq("Bot abc123")
    end

    it "doesn't double-prefix an already-prefixed token" do
      allow(described_class).to receive(:token).and_return("Bot abc123")
      expect(described_class.rest_token).to eq("Bot abc123")
    end
  end
end
