# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe ".from_omniauth" do
    subject(:user) { described_class.from_omniauth(auth) }

    let(:auth) { OmniAuth::AuthHash.new(provider: "discord", uid: "12345", info: {name: "shrk"}) }

    it "creates a user from the Discord identity" do
      expect { user }.to change(described_class, :count).by(1)
      expect(user).to have_attributes(discord_id: 12345, username: "shrk")
    end

    context "with a display name and avatar" do
      let(:auth) do
        OmniAuth::AuthHash.new(
          provider: "discord",
          uid: "12345",
          info: {name: "shrk"},
          extra: {raw_info: {"global_name" => "Shrk", "avatar" => "abchash"}}
        )
      end

      it "captures the display name and avatar" do
        expect(user).to have_attributes(display_name: "Shrk", avatar: "abchash")
      end
    end

    context "when the user has signed in before" do
      let!(:existing) { described_class.create!(discord_id: 12345, username: "old name") }

      it "reuses the row and refreshes the username" do
        expect { user }.not_to change(described_class, :count)
        expect(existing.reload.username).to eq("shrk")
      end
    end
  end

  describe "#display_name" do
    it "uses the Discord display name when present" do
      expect(build(:user, display_name: "Shrk", username: "shrk").display_name).to eq("Shrk")
    end

    it "falls back to the username when blank" do
      expect(build(:user, display_name: nil, username: "shrk").display_name).to eq("shrk")
    end
  end

  describe "#avatar_url" do
    it "builds the Discord CDN url from the avatar hash" do
      user = build(:user, discord_id: 12345, avatar: "abchash")
      expect(user.avatar_url).to eq("https://cdn.discordapp.com/avatars/12345/abchash.png")
    end

    it "is nil without an avatar" do
      expect(build(:user, avatar: nil).avatar_url).to be_nil
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
