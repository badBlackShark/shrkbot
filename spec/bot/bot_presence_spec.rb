require "rails_helper"

RSpec.describe BotPresence do
  describe ".activity_text" do
    subject(:activity_text) { described_class.activity_text(count) }

    context "with zero servers" do
      let(:count) { 0 }

      it "pluralizes correctly" do
        expect(activity_text).to eq("/help • 0 servers")
      end
    end

    context "with one server" do
      let(:count) { 1 }

      it "uses singular form" do
        expect(activity_text).to eq("/help • 1 server")
      end
    end

    context "with multiple servers" do
      let(:count) { 5 }

      it "uses plural form" do
        expect(activity_text).to eq("/help • 5 servers")
      end
    end
  end

  describe ".update" do
    subject(:update) { described_class.update(bot) }

    let(:bot) { double("bot", servers: [1, 2, 3]) }

    it "pushes a Listening status with the current server count" do
      expect(bot).to receive(:update_status).with("online", "/help • 3 servers", nil, 0, false, 2)
      update
    end
  end
end
