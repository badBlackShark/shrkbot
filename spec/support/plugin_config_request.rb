# frozen_string_literal: true

RSpec.shared_context "plugin config request" do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }
  let(:config) { ServerConfiguration.find_by(discord_id: guild.id) }
  let(:turbo) { {headers: {"Accept" => "text/vnd.turbo-stream.html"}} }
end

RSpec.shared_examples "a config page that requires sign-in" do
  context "when signed out" do
    it "redirects to the sign-in page" do
      get plugin_path
      expect(response).to redirect_to(root_path)
    end
  end
end

RSpec.shared_examples "a config page that requires a manageable server" do
  context "when the user no longer manages the server" do
    before do
      allow(Bot::Discord::UserGuilds).to receive(:call).and_return([])
    end

    it "redirects to the picker" do
      get plugin_path
      expect(response).to redirect_to(servers_path)
    end
  end
end
