# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::OverrideSummary do
  include_context "component view context"

  subject(:html) { described_class.new(channel_id:, role_id:, labels:).render_in(view_context) }

  let(:server) { create(:server_configuration) }
  let(:labels) { Feeds::RouteLabels.new(server) }
  let(:text) { Nokogiri::HTML.fragment(html).text }

  let(:channel_id) { nil }
  let(:role_id) { nil }

  before do
    create(:server_channel, server_configuration: server, discord_id: 111, name: "clips")
    create(:server_role, server_configuration: server, discord_id: 222, name: "Streams")
    create(:server_role, server_configuration: server, discord_id: 333, name: "@everyone")
  end

  context "with no override" do
    it "renders nothing" do
      expect(html).to eq("")
    end
  end

  context "with a channel override" do
    let(:channel_id) { 111 }

    it "names the channel" do
      expect(text).to eq("Posts in #clips")
    end
  end

  context "with a role override" do
    let(:role_id) { 222 }

    it "names the role" do
      expect(text).to eq("Pings @Streams")
    end
  end

  context "with the everyone role" do
    let(:role_id) { 333 }

    it "does not double the @" do
      expect(text).to eq("Pings @everyone")
    end
  end

  context "with both" do
    let(:channel_id) { 111 }
    let(:role_id) { 222 }

    it "joins them on one line" do
      expect(text).to eq("Posts in #clips · Pings @Streams")
    end
  end

  context "with the explicit no-ping override" do
    let(:role_id) { Feeds::Twitch::Settings::NO_PING }

    it "says nobody is pinged" do
      expect(text).to eq("Pings no one")
    end
  end

  context "with ids that no longer exist" do
    let(:channel_id) { 999 }
    let(:role_id) { 999 }

    it "says what the list page says" do
      expect(text).to eq("Posts in channel deleted · Pings a role that was deleted")
    end
  end
end
