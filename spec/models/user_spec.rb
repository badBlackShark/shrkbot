require "rails_helper"

RSpec.describe User do
  describe ".from_omniauth" do
    subject(:user) { described_class.from_omniauth(auth) }

    let(:auth) { OmniAuth::AuthHash.new(provider: "discord", uid: "12345", info: {name: "shrk"}) }

    it "creates a user from the Discord identity" do
      expect { user }.to change(described_class, :count).by(1)
      expect(user).to have_attributes(discord_id: 12345, username: "shrk")
    end

    context "when the user has signed in before" do
      let!(:existing) { described_class.create!(discord_id: 12345, username: "old name") }

      it "reuses the row and refreshes the username" do
        expect { user }.not_to change(described_class, :count)
        expect(existing.reload.username).to eq("shrk")
      end
    end
  end

  describe "validations" do
    subject(:user) { build(:user) }

    it { expect(user).to be_valid }

    it "requires a unique discord_id" do
      described_class.create!(discord_id: 999, username: "a")
      expect(build(:user, discord_id: 999)).not_to be_valid
    end
  end
end
