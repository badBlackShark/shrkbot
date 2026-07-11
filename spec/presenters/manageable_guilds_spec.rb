# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManageableGuilds do
  describe ".for" do
    subject(:guilds) { described_class.for("tok") }

    let(:manageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: true, member_count: 50, id: 1)
    end
    let(:unmanageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: false, member_count: 200, id: 2)
    end
    let(:large_manageable_guild) do
      instance_double("Bot::Discord::Guild", manageable?: true, member_count: 500, id: 3)
    end

    before do
      allow(Bot::Discord::UserGuilds).to receive(:call).with("tok").and_return(
        [manageable_guild, unmanageable_guild, large_manageable_guild]
      )
    end

    it "returns only manageable guilds" do
      expect(guilds).to contain_exactly(manageable_guild, large_manageable_guild)
    end

    it "sorts by member_count descending" do
      expect(guilds.map(&:id)).to eq([3, 1])
    end
  end
end
