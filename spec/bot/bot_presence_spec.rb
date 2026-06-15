require "rails_helper"

RSpec.describe BotPresence do
  describe ".activity_text" do
    it "pluralizes the server count" do
      expect(described_class.activity_text(0)).to eq("/help • 0 servers")
      expect(described_class.activity_text(1)).to eq("/help • 1 server")
      expect(described_class.activity_text(5)).to eq("/help • 5 servers")
    end
  end

  describe ".update" do
    it "pushes a Listening status with the current server count" do
      bot = double("bot", servers: [1, 2, 3])
      expect(bot).to receive(:update_status).with("online", "/help • 3 servers", nil, 0, false, 2)
      described_class.update(bot)
    end
  end
end
