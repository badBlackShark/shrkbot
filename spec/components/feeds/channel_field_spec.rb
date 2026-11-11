# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::ChannelField do
  include_context "component view context"

  subject(:fragment) do
    html = described_class.new(subscription:, name: "subscription[channel_id]", selected:, label: "Pick one", placeholder: "Choose a channel", **extra).render_in(view_context)
    Nokogiri::HTML5.fragment(html)
  end

  let(:server_configuration) { create(:server_configuration) }
  let(:subscription) { build(:feed_subscription, :twitch, server_configuration:) }
  let(:selected) { 111 }
  let(:extra) { {} }
  let(:select) { fragment.at_css("select") }

  before do
    create(:server_channel, server_configuration:, discord_id: 111, name: "clips")
    create(:server_channel, discord_id: 222, name: "elsewhere")
  end

  it "names the select and labels it" do
    expect(select["name"]).to eq("subscription[channel_id]")
    expect(fragment.text).to include("Pick one")
  end

  it "offers a blank option and only this server's channels, with the stored one chosen" do
    expect(select.css("option").map { |option| option["value"] }).to eq(["", "111"])
    expect(select.at_css("option[selected]")["value"]).to eq("111")
  end

  context "without a stored channel" do
    let(:selected) { nil }

    it "chooses nothing" do
      expect(select.css("option[selected]").map { |option| option["value"] }).to all(eq(""))
    end
  end

  it "is optional by default" do
    expect(select["aria-required"]).to be_nil
  end

  context "when required" do
    let(:extra) { {required: true} }

    it "marks the select required" do
      expect(select["aria-required"]).to eq("true")
    end
  end
end
