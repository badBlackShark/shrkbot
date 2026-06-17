require "rails_helper"

RSpec.describe Roles::Message do
  describe ".public_message" do
    subject(:message) { described_class.public_message(set) }

    let(:set) { create(:role_set, name: "Game Roles") }

    before do
      create(:assignable_role, role_set: set, label: "Gamer", emoji: "🎮", position: 0)
      create(:assignable_role, role_set: set, label: "Artist", emoji: nil, position: 1)
    end

    it "lists the set name and its roles in order" do
      expect(message[:content]).to eq("**Game Roles**\n🎮 Gamer\nArtist")
    end

    it "includes a manage button carrying the set's custom id" do
      button = message[:components].first[:components].first
      expect(button).to include(label: "Manage Roles", custom_id: Roles::CustomId.manage(set))
    end
  end
end
