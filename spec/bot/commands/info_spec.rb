require "rails_helper"

RSpec.describe Commands::Info do
  subject(:execute) { described_class.new(event).execute }

  let(:profile) { double("profile", username: "shrkbot", avatar_url: "https://cdn/avatar.png") }
  let(:event) { double("event", bot: double("bot", profile: profile), respond: nil) }

  it "responds with an embed" do
    expect(event).to receive(:respond) do |args|
      embed = args[:embeds].first
      expect(embed[:author]).to eq(name: "shrkbot", icon_url: "https://cdn/avatar.png")
      expect(embed[:description]).to include(described_class::INVITE_URL)
      expect(embed[:description]).to include("Ruby")
      expect(embed[:fields].first[:value]).to include("discordrb").and include("Ruby on Rails")
      expect(embed[:footer][:text]).to include("/donate")
    end

    execute
  end
end
