# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServerRoleOptions do
  subject(:options) { described_class.new(server).options }

  let(:server) { create(:server_configuration) }

  before do
    create(:server_role, server_configuration: server, discord_id: 222, name: "Second", position: 1, color: 0)
    create(:server_role, server_configuration: server, discord_id: 111, name: "First", position: 0, color: 0x1abc9c)
  end

  it "orders roles by position" do
    expect(options.map(&:label)).to eq(%w[First Second])
  end

  it "carries value, label and color" do
    first = options.first

    expect(first).to have_attributes(value: 111, label: "First", color: "#1abc9c")
  end

  it "falls back to the default color when the role color is zero" do
    expect(options.last.color).to eq(ServerRoleOptions::DEFAULT_COLOR)
  end
end
