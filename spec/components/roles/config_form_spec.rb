# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Roles::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  before do
    create(:role_setting, server_configuration: config)
    create(:server_channel, server_configuration: config, channel_type: 0)
  end

  it "marks the default channel label required" do
    label = Nokogiri::HTML5.fragment(html).css("label").find { |node| node.text.include?("Default channel for role menus") }
    expect(label.at_css("span.text-danger").text).to eq("*")
  end

  it "requires the default channel select" do
    select = Nokogiri::HTML5.fragment(html).at_css('select[name="roles[channel_id]"]')
    expect(select["aria-required"]).to eq("true")
  end

  context "when no channels have synced" do
    before do
      ServerChannel.where(server_configuration: config).destroy_all
    end

    it "shows the none-message" do
      expect(html).to include("No channels have synced yet")
    end
  end

  it "renders no bot-position callout when roles sit below the bot" do
    expect(html).not_to include("at the very bottom")
  end

  context "when the bot role sits at the bottom of the role list" do
    let(:config) { create(:server_configuration, bot_role_position: 1) }

    before do
      create(:server_role, server_configuration: config, discord_id: 10, name: "Member", position: 2)
    end

    it "recommends moving the bot role up" do
      expect(html).to include("at the very bottom")
    end
  end

  context "when a guild has a category with child text channels" do
    before do
      create(:server_channel, server_configuration: config, name: "General", channel_type: 4, discord_id: 900, position: 0)
      create(:server_channel, server_configuration: config, name: "chat", channel_type: 0, discord_id: 901, position: 0, parent_id: 900)
    end

    it "renders without raising NoMethodError" do
      expect { html }.not_to raise_error
    end
  end
end
