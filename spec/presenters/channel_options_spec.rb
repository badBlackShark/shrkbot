# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChannelOptions do
  subject(:options) { described_class.new(server).options }

  let(:server) { create(:server_configuration) }

  before do
    create(:server_channel, server_configuration: server, name: "info", channel_type: 4, discord_id: 10, position: 0)
    create(:server_channel, server_configuration: server, name: "rules", channel_type: 0, discord_id: 11, position: 0, parent_id: 10)
    create(:server_channel, server_configuration: server, name: "faq", channel_type: 0, discord_id: 12, position: 1, parent_id: 10)
    create(:server_channel, server_configuration: server, name: "welcome", channel_type: 0, discord_id: 1, position: 0)
  end

  it "lists uncategorised channels as bare options before any group" do
    expect(options.first).to have_attributes(value: 1, label: "welcome")
  end

  it "wraps categorised channels in a group named after their category, in position order" do
    group = options.last

    expect(group.label).to eq("info")
    expect(group.options.map(&:label)).to eq(%w[rules faq])
  end

  it "does not offer the category itself as a pickable option" do
    labels = options.flat_map { |entry| entry.is_a?(Components::TomSelect::Group) ? entry.options : entry }.map(&:label)

    expect(labels).not_to include("info")
  end
end
