# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Server listing rate limit", type: :request do
  include_context "discord auth"

  let(:guild) { Bot::Discord::Guild.new(id: 900_000_001, name: "Dev Refuge", owner: true, permissions: 0, icon: nil, member_count: 5) }

  before do
    post "/auth/discord/callback"
    create(:server_configuration, discord_id: guild.id)
    allow(Bot::Discord::UserGuilds).to receive(:call).and_return([guild])
  end

  it "serves the listing when under the limit" do
    get servers_path
    expect(response).to have_http_status(:ok)
  end

  it "refuses further listings once the per-user limit is exceeded" do
    allow(Rails.cache).to receive(:increment).and_return(9_999)

    get servers_path

    expect(response).to have_http_status(:too_many_requests)
  end
end
