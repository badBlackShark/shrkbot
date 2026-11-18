# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::OverrideSummary do
  include_context "component view context"

  subject(:html) do
    described_class.new(channel_id:, role_id:, labels: described_class::Labels.new(channels: {111 => "#clips"}, roles: {222 => "Streams"})).render_in(view_context)
  end

  let(:text) { Nokogiri::HTML.fragment(html).text }

  let(:channel_id) { nil }
  let(:role_id) { nil }

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

    it "renders nothing" do
      expect(html).to eq("")
    end
  end
end
