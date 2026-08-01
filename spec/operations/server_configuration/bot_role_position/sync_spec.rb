# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::BotRolePosition::Sync do
  subject(:result) { described_class.call(server_configuration: server, position: 7) }

  let(:server) { create(:server_configuration) }

  it "returns a successful result" do
    expect(result).to be_success
  end

  it "returns the updated server configuration" do
    expect(result.value).to eq(server)
  end

  it "writes the position to the record" do
    result
    expect(server.reload.bot_role_position).to eq(7)
  end
end
